require("dotenv").config();

const WebSocket = require("ws");
const express = require("express");
const cors = require("cors");
const http = require("http");
const { v4: uuidv4 } = require("uuid");

const handleRequest = require("./handlers/requestHandler");
const db = require("./firebase");
const paymentRoutes = require("./payment-gateway/paymentRoutes");

const app = express();

console.log("Express initialized successfully");

/*
========================
HEALTH ROUTE (IMPORTANT)
========================
*/

app.get("/", (req, res) => {
  res.status(200).send("Railway backend alive 🚀");
});

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true })); // Required for CCAvenue form POST callbacks

/*
========================
PAYMENT GATEWAY ROUTES
========================
*/

app.use("/api/payment", paymentRoutes);
app.use("/payment", paymentRoutes);
console.log("💳 CCAvenue payment routes mounted at /api/payment and /payment");

/*
========================
PORT CONFIG
========================
*/

const PORT = process.env.PORT;

/*
========================
CREATE HTTP + WS SERVER
========================
*/

const server = http.createServer(app);

const wss = new WebSocket.Server({
  server,
  skipUTF8Validation: true,
});

console.log(`Server starting on port ${PORT}`);

const chargers = {};
const pendingCalls = new Map();
const stationTelemetry = new Map();

/*
========================
TELEMETRY STORAGE
========================
*/

function getTelemetry(stationId) {
  if (!stationTelemetry.has(stationId)) {
    stationTelemetry.set(stationId, {
      lastSeenAt: null,
      lastHeartbeatAt: null,
      lastStatusNotification: null,
      lastMeterValues: null,
      lastRemoteStart: null,
      lastRemoteStop: null,
    });
  }

  return stationTelemetry.get(stationId);
}

/*
========================
STATUS COMPUTATION
========================
*/

function computeStationStatus(stationId) {
  const connected = Boolean(chargers[stationId]);
  const telemetry = stationTelemetry.get(stationId) || null;

  if (!connected) {
    return { connected: false, status: "Unavailable", telemetry };
  }

  const lastStatus = telemetry?.lastStatusNotification?.status;

  if (lastStatus === "Charging") {
    return { connected: true, status: "Charging", telemetry };
  }

  if (lastStatus === "Preparing") {
    return { connected: true, status: "Preparing", telemetry };
  }

  return { connected: true, status: "Available", telemetry };
}

/*
========================
CHARGER CONNECTION
========================
*/

wss.on("connection", (ws, request) => {

  console.log("Incoming WS connection attempt:", request.url);

  const urlParts = request.url.split("/");

  let chargePointId;

  if (urlParts[1] === "ocpp") {
    chargePointId = urlParts[2];
  } else if (urlParts[1] === "ws" && urlParts[2] === "1.6") {
    chargePointId = urlParts[3];
  } else {
    chargePointId = urlParts[1];
  }

  chargers[chargePointId] = ws;
  console.log(`🔌 ChargePoint Connected: ${chargePointId}`);

  // Automatically update Firestore online status
  (async () => {
    try {
      const stationRef = db.collection("stations").doc(chargePointId);
      const stationDoc = await stationRef.get();
      if (stationDoc.exists) {
        await stationRef.set({
          isOnline: true,
          status: "Available",
          lastSeen: new Date()
        }, { merge: true });
        console.log(`Updated Firestore: ${chargePointId} is now online.`);
      }
    } catch (err) {
      console.error(`Failed to update online status for ${chargePointId}:`, err);
    }
  })();

  ws.on("message", async (message) => {

    try {

      const msg = JSON.parse(message.toString());

      const messageTypeId = msg[0];
      const uniqueId = msg[1];

      if (messageTypeId === 2) {

        const action = msg[2];
        const payload = msg[3] || {};

        const telemetry = getTelemetry(chargePointId);

        telemetry.lastSeenAt = new Date().toISOString();

        if (action === "Heartbeat") {
          telemetry.lastHeartbeatAt = telemetry.lastSeenAt;
        }

        if (action === "StatusNotification") {
          telemetry.lastStatusNotification = {
            at: telemetry.lastSeenAt,
            status: payload?.status,
          };
        }

        if (action === "MeterValues") {
          telemetry.lastMeterValues = payload;
        }

        await handleRequest(
          ws,
          uniqueId,
          action,
          payload,
          chargePointId
        );

      }

      if (messageTypeId === 3 || messageTypeId === 4) {

        const pending = pendingCalls.get(uniqueId);

        if (!pending) return;

        pendingCalls.delete(uniqueId);

        if (messageTypeId === 3) {
          pending.resolve(msg[2] || {});
        } else {
          pending.reject(new Error("CallError"));
        }

      }

    } catch (err) {

      console.error("Invalid message format:", err);

    }

  });

  ws.on("close", async () => {

    delete chargers[chargePointId];

    console.log(`❌ ChargePoint Disconnected: ${chargePointId}`);

    try {
      const stationRef = db.collection("stations").doc(chargePointId);
      const stationDoc = await stationRef.get();
      if (stationDoc.exists) {
        await stationRef.set({
          isOnline: false,
          status: "Unavailable",
          lastSeen: new Date()
        }, { merge: true });
        console.log(`Updated Firestore: ${chargePointId} is now offline.`);
      }
    } catch (err) {
      console.error(`Failed to update offline status for ${chargePointId}:`, err);
    }

  });

});

/*
========================
REMOTE START FUNCTION
========================
*/

function sendCallAndAwaitResult(stationId, action, payload) {

  const charger = chargers[stationId];

  if (!charger) {
    throw new Error(`Charger not connected: ${stationId}`);
  }

  const message = [
    2,
    uuidv4(),
    action,
    payload || {},
  ];

  const uniqueId = message[1];

  const resultPromise = new Promise((resolve, reject) => {

    const timeoutId = setTimeout(() => {

      pendingCalls.delete(uniqueId);

      reject(new Error(`${action} timed out`));

    }, 60000);

    pendingCalls.set(uniqueId, {

      resolve: (responsePayload) => {

        clearTimeout(timeoutId);

        resolve(responsePayload);

      },

      reject,

    });

  });

  charger.send(JSON.stringify(message));

  return resultPromise;
}

/*
========================
HTTP API ROUTES
========================
*/

app.get("/stations/:stationId/status", (req, res) => {

  const stationId = req.params.stationId;

  res.json({
    stationId,
    ...computeStationStatus(stationId),
  });

});

// Debug: List all currently connected chargers
app.get("/debug/chargers", (req, res) => {
  const connected = Object.keys(chargers).map((id) => ({
    id,
    readyState: chargers[id]?.readyState, // 0=CONNECTING, 1=OPEN, 2=CLOSING, 3=CLOSED
  }));
  console.log("🔍 Debug: Connected chargers:", connected);
  res.json({ count: connected.length, chargers: connected });
});

app.post("/remote-start", async (req, res) => {

  const { stationId, connectorId, idTag } = req.body;

  console.log("─────────────────────────────────────────────");
  console.log("⚡ POST /remote-start received");
  console.log("   stationId:", stationId);
  console.log("   connectorId:", connectorId || 1);
  console.log("   idTag:", idTag || "WEB_APP");
  console.log("   Connected chargers:", Object.keys(chargers));
  console.log("─────────────────────────────────────────────");

  if (!stationId) {
    return res.status(400).json({
      error: "stationId required",
    });
  }

  // Check if the charger is actually connected
  if (!chargers[stationId]) {
    console.error(`❌ Charger "${stationId}" is NOT in the connected chargers map.`);
    console.log("   Available chargers:", Object.keys(chargers));
    return res.status(500).json({
      error: `Charger not connected: ${stationId}. Connected chargers: [${Object.keys(chargers).join(", ")}]`,
    });
  }

  try {

    // OCPP 1.6 requires idTag to be 20 characters max (Firebase UID is 28 chars, which fails on physical chargers)
    const ocppIdTag = String(idTag || "WEB_APP").substring(0, 20);

    const payload = await sendCallAndAwaitResult(
      stationId,
      "RemoteStartTransaction",
      { connectorId: connectorId || 1, idTag: ocppIdTag }
    );

    console.log("✅ RemoteStartTransaction response from charger:", JSON.stringify(payload));

    // Update Firestore status to Preparing
    try {
      await db.collection("stations").doc(stationId).set({
        status: "Preparing",
        lastSeen: new Date()
      }, { merge: true });
    } catch (e) {
      console.error("Failed to update station status to Preparing:", e);
    }

    res.json(payload);

  } catch (error) {

    console.error("❌ RemoteStartTransaction error:", error.message);
    res.status(500).json({
      error: error.message,
    });

  }

});

app.post("/remote-stop", async (req, res) => {

  const { stationId, transactionId } = req.body;

  if (!stationId) {
    return res.status(400).json({
      error: "stationId required",
    });
  }

  let finalTxId = Number(transactionId);

  // If no transaction ID was provided or it is invalid, attempt to look it up in Firestore
  if (!finalTxId || isNaN(finalTxId)) {
    console.log(`🔍 No transactionId provided for remote-stop on ${stationId}. Querying database...`);
    try {
      const activeTxSnap = await db.collection("transactions")
        .where("stationId", "==", stationId)
        .where("status", "==", "active")
        .limit(1)
        .get();

      if (!activeTxSnap.empty) {
        finalTxId = Number(activeTxSnap.docs[0].data().ocppTransactionId);
        console.log(`🎯 Found active transaction ID in Firestore for ${stationId}: ${finalTxId}`);
      } else {
        console.log(`⚠️ No active transaction found in Firestore for ${stationId}`);
      }
    } catch (dbErr) {
      console.error("Failed to query active transaction ID:", dbErr);
    }
  }

  // Fallback default value if lookup also failed (so the OCPP message is still valid structurally)
  if (!finalTxId || isNaN(finalTxId)) {
    finalTxId = 1; 
  }

  try {

    const payload = await sendCallAndAwaitResult(
      stationId,
      "RemoteStopTransaction",
      { transactionId: finalTxId }
    );

    res.json(payload);

  } catch (error) {

    res.status(500).json({
      error: error.message,
    });

  }

});


/*
========================
START SERVER
========================
*/

server.listen(PORT, "0.0.0.0", () => {

  console.log(`🚀 Server running on Railway port ${PORT}`);

});