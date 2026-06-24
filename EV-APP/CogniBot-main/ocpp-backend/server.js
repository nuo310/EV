require("dotenv").config();

const WebSocket = require("ws");
const express = require("express");
const cors = require("cors");
const http = require("http");
const { v4: uuidv4 } = require("uuid");

const handleRequest = require("./handlers/requestHandler");
const db = require("./firebase");

// ── Payment gateway disabled — direct OCPP charger control only ──
// const paymentRoutes = require("./payment-gateway/paymentRoutes");

const app = express();

console.log("Express initialized successfully");

/*
========================
HEALTH ROUTE (IMPORTANT)
========================
*/

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true })); // Required for CCAvenue form POST callbacks

app.get("/", (req, res) => {
  res.status(200).send("Railway backend alive 🚀");
});

/*
========================
PAYMENT GATEWAY ROUTES (DISABLED)
========================
Payment gateway commented out — physical charger uses direct OCPP start/stop.
To re-enable: uncomment the paymentRoutes require above and the lines below.
*/

// app.use("/api/payment", paymentRoutes);
// app.use("/payment", paymentRoutes);
// console.log("💳 CCAvenue payment routes mounted at /api/payment and /payment");

/*
========================
WEBSOCKET INFO ENDPOINT
========================
Returns the WebSocket URL format for charger onboarding.
The admin panel uses this to display the URL that charger operators
must configure on their physical OCPP charger.
*/

app.get("/ws-info", (req, res) => {
  // Derive WebSocket URL from the request's host
  const protocol = req.headers['x-forwarded-proto'] === 'https' ? 'wss' : 'ws';
  const host = req.headers['x-forwarded-host'] || req.headers.host || `localhost:${PORT}`;
  const baseWsUrl = `${protocol}://${host}`;

  res.json({
    websocketUrl: `${baseWsUrl}/ocpp/{CHARGER_ID}`,
    websocketUrlAlt: `${baseWsUrl}/ws/1.6/{CHARGER_ID}`,
    instructions: [
      "1. Open your physical charger's OCPP configuration panel",
      "2. Set the OCPP Server URL to the websocketUrl above, replacing {CHARGER_ID} with your station's unique ID",
      "3. Set OCPP Version to 1.6J (JSON over WebSocket)",
      "4. Save and restart the charger",
      "5. The charger will auto-connect and register on your platform via BootNotification",
    ],
    supportedFormats: [
      "/ocpp/{CHARGER_ID}",
      "/ws/1.6/{CHARGER_ID}",
      "/{CHARGER_ID}",
    ],
    subprotocol: "ocpp1.6",
    port: PORT,
  });
});

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
  handleProtocols: (protocols) => {
    if (protocols.has("ocpp1.6")) return "ocpp1.6";
    if (protocols.has("ocpp2.0.1")) return "ocpp2.0.1";
    // Allow connections without subprotocol (e.g. browser debug tools)
    return false;
  },
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

  // Parse path and query parameters safely to avoid Charger ID corruption
  const reqHost = request.headers['x-forwarded-host'] || request.headers.host || 'localhost';
  const parsedUrl = new URL(request.url, `http://${reqHost}`);
  const pathname = parsedUrl.pathname;
  const urlParts = pathname.split("/");

  let chargePointId;

  if (urlParts[1] === "ocpp") {
    chargePointId = urlParts[2];
  } else if (urlParts[1] === "ws" && urlParts[2] === "1.6") {
    chargePointId = urlParts[3];
  } else {
    chargePointId = urlParts[1];
  }

  // Reject connections with missing or invalid charger ID
  if (!chargePointId || chargePointId.trim() === "") {
    console.warn("⚠️ Rejecting WebSocket connection with no charger ID:", request.url);
    ws.close(1008, "Missing charger identity");
    return;
  }

  // Extract latitude & longitude from connection query parameters if present
  const latParam = parsedUrl.searchParams.get("lat") || parsedUrl.searchParams.get("latitude");
  const lngParam = parsedUrl.searchParams.get("lng") || parsedUrl.searchParams.get("longitude");
  if (latParam && lngParam) {
    const parsedLat = parseFloat(latParam);
    const parsedLng = parseFloat(lngParam);
    if (!isNaN(parsedLat) && !isNaN(parsedLng)) {
      ws.latitude = parsedLat;
      ws.longitude = parsedLng;
      console.log(`📍 Parsed charger coordinates from URL: lat=${parsedLat}, lng=${parsedLng}`);
    }
  }

  chargers[chargePointId] = ws;
  console.log(`🔌 ChargePoint Connected: ${chargePointId}`);

  // Capture the connection WebSocket URL for storage / diagnostics
  const protocol = request.headers['x-forwarded-proto'] === 'https' ? 'wss' : 'ws';
  const host = request.headers['x-forwarded-host'] || request.headers.host || `localhost:${PORT}`;
  const connectionWsUrl = `${protocol}://${host}${request.url}`;
  ws.connectionWsUrl = connectionWsUrl;

  // Automatically update Firestore online status
  (async () => {
    try {
      const stationRef = db.collection("stations").doc(chargePointId);
      const stationDoc = await stationRef.get();
      if (stationDoc.exists) {
        const updateData = {
          isOnline: true,
          status: "Available",
          lastSeen: new Date(),
          websocketUrl: connectionWsUrl
        };
        if (ws.latitude && ws.longitude) {
          updateData.lat = ws.latitude;
          updateData.lng = ws.longitude;
        }
        await stationRef.set(updateData, { merge: true });
        console.log(`Updated Firestore: ${chargePointId} is now online. WebSocket URL: ${connectionWsUrl}`);
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

  ws.on("error", (err) => {
    console.error(`WebSocket error for ${chargePointId}:`, err.message);
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

    // Automatically terminate any active sessions on this station because it went offline
    try {
      const txSnap = await db.collection("transactions")
        .where("stationId", "==", chargePointId)
        .where("status", "==", "active")
        .get();
      for (const doc of txSnap.docs) {
        const data = doc.data();
        await doc.ref.update({
          status: "completed",
          endedAt: new Date(),
          meterStop: data.meterStart || 0
        });
        console.log(`Terminated active transaction ${doc.id} (station went offline).`);
      }
    } catch (txErr) {
      console.error(`Failed to terminate active transactions for offline station ${chargePointId}:`, txErr);
    }

    try {
      const bookingSnap = await db.collection("bookings")
        .where("stationId", "==", chargePointId)
        .where("status", "==", "active")
        .get();
      for (const doc of bookingSnap.docs) {
        const data = doc.data();
        await doc.ref.update({
          status: "completed",
          completedAt: new Date(),
          endedAt: new Date(),
          meterStopWh: data.meterStartWh || 0
        });
        console.log(`Terminated active booking ${doc.id} (station went offline).`);
      }
    } catch (bkErr) {
      console.error(`Failed to terminate active bookings for offline station ${chargePointId}:`, bkErr);
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

  if (charger.readyState !== WebSocket.OPEN) {
    delete chargers[stationId];
    throw new Error(`Charger WebSocket not open (state=${charger.readyState}): ${stationId}`);
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

      reject: (err) => {
        clearTimeout(timeoutId);
        reject(err);
      },

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

  console.log("Connected chargers:", chargers)

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

  console.log("hit remote stop")

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
        console.log(`⚠️ No active transaction found in Firestore for ${stationId}. Falling back to most recent transaction...`);
        // Fallback: Query recent transactions for this station and sort in-memory to find the most recent transaction
        const recentTxSnap = await db.collection("transactions")
          .where("stationId", "==", stationId)
          .limit(10)
          .get();
        if (!recentTxSnap.empty) {
          const docs = recentTxSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
          docs.sort((a, b) => {
            const tA = a.timestamp ? (a.timestamp.toDate ? a.timestamp.toDate() : new Date(a.timestamp)) : new Date(0);
            const tB = b.timestamp ? (b.timestamp.toDate ? b.timestamp.toDate() : new Date(b.timestamp)) : new Date(0);
            return tB - tA; // sort desc
          });
          finalTxId = Number(docs[0].ocppTransactionId);
          console.log(`🎯 Found most recent transaction ID in Firestore (in-memory sort) for ${stationId}: ${finalTxId}`);
        } else {
          console.log(`⚠️ No transactions whatsoever found in Firestore for ${stationId}`);
        }
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

});/*
========================
ADMIN STATION CRUD ROUTES
========================
*/

app.post("/admin/stations", async (req, res) => {
  try {
    const { stationId, ...rest } = req.body;
    if (!stationId) {
      return res.status(400).json({ error: "stationId is required" });
    }
    
    // Parse coordinates and numbers correctly
    const data = {
      ...rest,
      lat: rest.lat !== undefined && rest.lat !== "" ? parseFloat(rest.lat) : null,
      lng: rest.lng !== undefined && rest.lng !== "" ? parseFloat(rest.lng) : null,
      pricePerHour: rest.pricePerHour !== undefined ? parseFloat(rest.pricePerHour) : 15,
      energyRatePerKwh: rest.energyRatePerKwh !== undefined ? parseFloat(rest.energyRatePerKwh) : 12,
      availableSlots: rest.availableSlots !== undefined ? parseInt(rest.availableSlots) : 1,
      connectorId: rest.connectorId !== undefined ? parseInt(rest.connectorId) : 1,
      published: rest.published !== false,
      isOnline: rest.isOnline !== false,
      lastSeen: new Date(),
    };
    
    await db.collection("stations").doc(stationId).set(data, { merge: true });
    res.status(201).json({ success: true, stationId });
  } catch (err) {
    console.error("Error creating station:", err);
    res.status(500).json({ error: err.message });
  }
});

app.put("/admin/stations/:stationId", async (req, res) => {
  try {
    const { stationId } = req.params;
    const body = req.body;
    
    const updateData = {};
    if (body.name !== undefined) updateData.name = body.name;
    if (body.websocketUrl !== undefined) updateData.websocketUrl = body.websocketUrl;
    if (body.lat !== undefined && body.lat !== "") updateData.lat = parseFloat(body.lat);
    if (body.lng !== undefined && body.lng !== "") updateData.lng = parseFloat(body.lng);
    if (body.chargerType !== undefined) updateData.chargerType = body.chargerType;
    if (body.connectorId !== undefined) updateData.connectorId = parseInt(body.connectorId);
    if (body.pricePerHour !== undefined) updateData.pricePerHour = parseFloat(body.pricePerHour);
    if (body.energyRatePerKwh !== undefined) updateData.energyRatePerKwh = parseFloat(body.energyRatePerKwh);
    if (body.availableSlots !== undefined) updateData.availableSlots = parseInt(body.availableSlots);
    if (body.published !== undefined) updateData.published = Boolean(body.published);
    if (body.isOnline !== undefined) updateData.isOnline = Boolean(body.isOnline);
    if (body.vendor !== undefined) updateData.vendor = body.vendor;
    if (body.model !== undefined) updateData.model = body.model;
    if (body.status !== undefined) updateData.status = body.status;
    if (body.errorCode !== undefined) updateData.errorCode = body.errorCode;
    
    updateData.lastSeen = new Date();
    
    await db.collection("stations").doc(stationId).set(updateData, { merge: true });
    res.json({ success: true, stationId });
  } catch (err) {
    console.error("Error updating station:", err);
    res.status(500).json({ error: err.message });
  }
});

app.delete("/admin/stations/:stationId", async (req, res) => {
  try {
    const { stationId } = req.params;
    await db.collection("stations").doc(stationId).delete();
    res.json({ success: true, stationId });
  } catch (err) {
    console.error("Error deleting station:", err);
    res.status(500).json({ error: err.message });
  }
});


/*
========================
START SERVER
========================
*/

server.listen(PORT, "0.0.0.0", async () => {

  console.log(`🚀 Server running on Railway port ${PORT}`);

  // Boot-time self-healing check: Clean up any stuck active bookings/transactions on offline/unavailable chargers
  try {
    console.log("🧹 Running boot-time self-healing cleanup check...");
    const stationsSnap = await db.collection("stations").get();
    for (const stationDoc of stationsSnap.docs) {
      const station = stationDoc.data();
      const isOnline = station.isOnline === true;
      const status = (station.status || "").toLowerCase();
      
      // If the station is offline or unavailable, clean up active bookings/transactions
      if (!isOnline || status === "unavailable" || status === "faulted") {
        const stationId = stationDoc.id;
        
        // 1. Terminate stuck transactions
        const txSnap = await db.collection("transactions")
          .where("stationId", "==", stationId)
          .where("status", "==", "active")
          .get();
        for (const doc of txSnap.docs) {
          const data = doc.data();
          await doc.ref.update({
            status: "completed",
            endedAt: new Date(),
            meterStop: data.meterStart || 0
          });
          console.log(`🧹 [Boot Cleanup] Terminated active transaction ${doc.id} on offline station ${stationId}`);
        }

        // 2. Terminate stuck bookings
        const bookingSnap = await db.collection("bookings")
          .where("stationId", "==", stationId)
          .where("status", "==", "active")
          .get();
        for (const doc of bookingSnap.docs) {
          const data = doc.data();
          await doc.ref.update({
            status: "completed",
            completedAt: new Date(),
            endedAt: new Date(),
            meterStopWh: data.meterStartWh || 0
          });
          console.log(`🧹 [Boot Cleanup] Terminated active booking ${doc.id} on offline station ${stationId}`);
        }
      }
    }
    console.log("🧹 Boot-time self-healing cleanup check completed.");
  } catch (err) {
    console.error("🧹 Boot-time self-healing cleanup check failed:", err);
  }

});