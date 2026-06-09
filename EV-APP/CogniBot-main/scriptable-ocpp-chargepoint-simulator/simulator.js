/*
 * ═══════════════════════════════════════════════════════════
 *  OCPP 1.6 CHARGER SIMULATOR — DISABLED
 * ═══════════════════════════════════════════════════════════
 *
 *  This simulator is no longer needed. The platform now connects
 *  to PHYSICAL EV chargers via OCPP 1.6 WebSocket.
 *
 *  How the real charger connects:
 *  1. Admin creates station in platform with an OCPP Station ID
 *  2. Charger operator configures the charger's OCPP settings:
 *     - Server URL: wss://your-server/ocpp/STATION_ID
 *     - OCPP Version: 1.6J
 *  3. Charger connects → sends BootNotification → auto-registers
 *  4. User clicks "Start Charging" → server sends RemoteStartTransaction
 *
 *  To test without a physical charger, you can temporarily
 *  uncomment the code below and run: node simulator.js
 * ═══════════════════════════════════════════════════════════
 */

const WebSocket = require("ws");

// -------------------------------------------------------------
// CONFIGURATION
// -------------------------------------------------------------
const BACKEND_URL = "ws://51.20.41.4:9221/ocpp/mgch001";
const CHARGE_POINT_ID = "mgch001";
const HEARTBEAT_INTERVAL_MS = 60000;
const METER_VALUE_INTERVAL_MS = 5000;

console.log(`🔌 Starting OCPP 1.6 Charger Simulator [ID: ${CHARGE_POINT_ID}]...`);
console.log(`🔗 Connecting to Backend: ${BACKEND_URL}`);

let ws;
let heartbeatTimer;
let meterTimer;
let currentTransactionId = null;
let bootNotificationUniqueId = null;
let currentMeterValueWh = 150000;

function connect() {
  ws = new WebSocket(BACKEND_URL);

  ws.on("open", () => {
    console.log("🟢 Connected to local OCPP backend!");
    sendBootNotification();
  });

  ws.on("message", (data) => {
    try {
      const message = JSON.parse(data.toString());
      handleIncomingMessage(message);
    } catch (error) {
      console.error("❌ Failed to parse incoming message:", error);
    }
  });

  ws.on("close", () => {
    console.log("🔴 Disconnected from backend. Reconnecting in 5 seconds...");
    clearInterval(heartbeatTimer);
    clearInterval(meterTimer);
    setTimeout(connect, 5000);
  });

  ws.on("error", (error) => {
    console.error("❌ WebSocket Error:", error.message);
  });
}

function sendBootNotification() {
  const uid = generateUniqueId();
  bootNotificationUniqueId = uid;
  const msg = [
    2, uid, "BootNotification",
    {
      chargePointVendor: "ZynkaTech Simulator",
      chargePointModel: "Z-Model-S",
      chargeBoxSerialNumber: "ZYNKA-SIM-9991",
      firmwareVersion: "v1.0.0-mock"
    }
  ];
  console.log("➡️ Sending BootNotification...");
  ws.send(JSON.stringify(msg));
}

function sendStatusNotification(status) {
  const msg = [
    2, generateUniqueId(), "StatusNotification",
    { connectorId: 1, errorCode: "NoError", status, timestamp: new Date().toISOString() }
  ];
  console.log(`➡️ Sending StatusNotification: ${status}`);
  ws.send(JSON.stringify(msg));
}

function sendHeartbeat() {
  const msg = [2, generateUniqueId(), "Heartbeat", {}];
  console.log("➡️ Sending Heartbeat...");
  ws.send(JSON.stringify(msg));
}

function sendStartTransaction(idTag) {
  const msg = [
    2, generateUniqueId(), "StartTransaction",
    { connectorId: 1, idTag, meterStart: currentMeterValueWh, timestamp: new Date().toISOString() }
  ];
  console.log(`➡️ Sending StartTransaction (idTag: ${idTag})...`);
  ws.send(JSON.stringify(msg));
}

function sendStopTransaction() {
  const msg = [
    2, generateUniqueId(), "StopTransaction",
    { transactionId: currentTransactionId, idTag: "WEB_APP", meterStop: currentMeterValueWh, timestamp: new Date().toISOString(), reason: "Local" }
  ];
  console.log(`➡️ Sending StopTransaction (transactionId: ${currentTransactionId})...`);
  ws.send(JSON.stringify(msg));
}

function sendMeterValues() {
  const powerIncrementWh = Math.floor(Math.random() * 25) + 25;
  currentMeterValueWh += powerIncrementWh;
  const msg = [
    2, generateUniqueId(), "MeterValues",
    {
      connectorId: 1, transactionId: currentTransactionId,
      meterValue: [{
        timestamp: new Date().toISOString(),
        sampledValue: [
          { value: currentMeterValueWh.toString(), context: "Sample.Periodic", format: "Raw", measurand: "Energy.Active.Import.Register", phase: "L1", location: "Outlet", unit: "Wh" },
          { value: "230", context: "Sample.Periodic", format: "Raw", measurand: "Voltage", phase: "L1-N", unit: "V" }
        ]
      }]
    }
  ];
  console.log(`⚡ Sending MeterValues (Current Wh: ${currentMeterValueWh})`);
  ws.send(JSON.stringify(msg));
}

function handleIncomingMessage(msg) {
  const messageTypeId = msg[0];
  const uniqueId = msg[1];

  if (messageTypeId === 2) {
    const action = msg[2];
    const payload = msg[3];
    console.log(`📥 Received Call Request: ${action}`, payload);

    if (action === "RemoteStartTransaction") {
      if (currentTransactionId !== null) {
        console.log("⚠️ Already in a charging session, rejecting duplicate RemoteStart");
        ws.send(JSON.stringify([3, uniqueId, { status: "Rejected" }]));
        return;
      }
      ws.send(JSON.stringify([3, uniqueId, { status: "Accepted" }]));
      console.log("➡️ Sent CallResult (Accepted) for RemoteStartTransaction");
      sendStatusNotification("Preparing");
      setTimeout(() => {
        sendStatusNotification("Charging");
        sendStartTransaction(payload.idTag || "WEB_APP");
      }, 2000);
    }
    else if (action === "RemoteStopTransaction") {
      ws.send(JSON.stringify([3, uniqueId, { status: "Accepted" }]));
      console.log("➡️ Sent CallResult (Accepted) for RemoteStopTransaction");
      if (currentTransactionId !== null) {
        clearInterval(meterTimer);
        sendStopTransaction();
        sendStatusNotification("Finishing");
        setTimeout(() => {
          sendStatusNotification("Available");
          currentTransactionId = null;
        }, 2000);
      }
    }
  }
  else if (messageTypeId === 3) {
    const payload = msg[2];
    console.log("📥 Received CallResult Response:", payload);
    if (uniqueId === bootNotificationUniqueId && payload.status === "Accepted") {
      bootNotificationUniqueId = null;
      sendStatusNotification("Available");
      if (!heartbeatTimer) heartbeatTimer = setInterval(sendHeartbeat, HEARTBEAT_INTERVAL_MS);
    }
    if (payload.transactionId && payload.idTagInfo && payload.idTagInfo.status === "Accepted") {
      currentTransactionId = payload.transactionId;
      console.log(`ℹ️ Session started with Backend TransactionID: ${currentTransactionId}`);
      meterTimer = setInterval(sendMeterValues, METER_VALUE_INTERVAL_MS);
    }
  }
}

function generateUniqueId() {
  return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
}

connect();
