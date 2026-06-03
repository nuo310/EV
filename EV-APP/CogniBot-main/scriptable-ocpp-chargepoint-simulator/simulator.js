const WebSocket = require("ws");

// -------------------------------------------------------------
// CONFIGURATION
// -------------------------------------------------------------
const BACKEND_URL = "ws://localhost:9221/ws/1.6/mgch001";
const CHARGE_POINT_ID = "mgch001";
const HEARTBEAT_INTERVAL_MS = 60000; // 60 seconds
const METER_VALUE_INTERVAL_MS = 5000; // 5 seconds (fast updates for UI testing)

console.log(`🔌 Starting OCPP 1.6 Charger Simulator [ID: ${CHARGE_POINT_ID}]...`);
console.log(`🔗 Connecting to Backend: ${BACKEND_URL}`);

let ws;
let heartbeatTimer;
let meterTimer;
let currentTransactionId = null;
let currentMeterValueWh = 150000; // Starts at 150 kWh

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

// -------------------------------------------------------------
// OCPP OUTGOING MESSAGES
// -------------------------------------------------------------

function sendBootNotification() {
  const msg = [
    2,
    generateUniqueId(),
    "BootNotification",
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
    2,
    generateUniqueId(),
    "StatusNotification",
    {
      connectorId: 1,
      errorCode: "NoError",
      status: status, // Available, Preparing, Charging, SuspendedEV, Finishing, Reserved, Unavailable, Faulted
      timestamp: new Date().toISOString()
    }
  ];
  console.log(`➡️ Sending StatusNotification: ${status}`);
  ws.send(JSON.stringify(msg));
}

function sendHeartbeat() {
  const msg = [
    2,
    generateUniqueId(),
    "Heartbeat",
    {}
  ];
  console.log("➡️ Sending Heartbeat...");
  ws.send(JSON.stringify(msg));
}

function sendStartTransaction(idTag) {
  const msg = [
    2,
    generateUniqueId(),
    "StartTransaction",
    {
      connectorId: 1,
      idTag: idTag,
      meterStart: currentMeterValueWh,
      timestamp: new Date().toISOString()
    }
  ];
  console.log(`➡️ Sending StartTransaction (idTag: ${idTag})...`);
  ws.send(JSON.stringify(msg));
}

function sendStopTransaction() {
  const msg = [
    2,
    generateUniqueId(),
    "StopTransaction",
    {
      transactionId: currentTransactionId,
      idTag: "WEB_APP",
      meterStop: currentMeterValueWh,
      timestamp: new Date().toISOString(),
      reason: "Local"
    }
  ];
  console.log(`➡️ Sending StopTransaction (transactionId: ${currentTransactionId})...`);
  ws.send(JSON.stringify(msg));
}

function sendMeterValues() {
  // Increase current meter value by 25-50 Wh per interval (simulate consumption)
  const powerIncrementWh = Math.floor(Math.random() * 25) + 25;
  currentMeterValueWh += powerIncrementWh;

  const msg = [
    2,
    generateUniqueId(),
    "MeterValues",
    {
      connectorId: 1,
      transactionId: currentTransactionId,
      meterValue: [
        {
          timestamp: new Date().toISOString(),
          sampledValue: [
            {
              value: currentMeterValueWh.toString(),
              context: "Sample.Periodic",
              format: "Raw",
              measurand: "Energy.Active.Import.Register",
              phase: "L1",
              location: "Outlet",
              unit: "Wh"
            },
            {
              value: "230", // standard 230V voltage
              context: "Sample.Periodic",
              format: "Raw",
              measurand: "Voltage",
              phase: "L1-N",
              unit: "V"
            }
          ]
        }
      ]
    }
  ];
  console.log(`⚡ Sending MeterValues (Current Wh: ${currentMeterValueWh})`);
  ws.send(JSON.stringify(msg));
}

// -------------------------------------------------------------
// OCPP INCOMING MESSAGE HANDLER
// -------------------------------------------------------------

function handleIncomingMessage(msg) {
  const messageTypeId = msg[0];
  const uniqueId = msg[1];

  // OCPP Call (Request from Backend)
  if (messageTypeId === 2) {
    const action = msg[2];
    const payload = msg[3];

    console.log(`📥 Received Call Request: ${action}`, payload);

    if (action === "RemoteStartTransaction") {
      // 1. Reply CallResult (Accepted) to Backend
      const response = [3, uniqueId, { status: "Accepted" }];
      ws.send(JSON.stringify(response));
      console.log("➡️ Sent CallResult (Accepted) for RemoteStartTransaction");

      // 2. Transition state to preparing -> charging
      sendStatusNotification("Preparing");
      
      setTimeout(() => {
        sendStatusNotification("Charging");
        sendStartTransaction(payload.idTag || "WEB_APP");
      }, 2000);
    } 
    
    else if (action === "RemoteStopTransaction") {
      // 1. Reply CallResult (Accepted) to Backend
      const response = [3, uniqueId, { status: "Accepted" }];
      ws.send(JSON.stringify(response));
      console.log("➡️ Sent CallResult (Accepted) for RemoteStopTransaction");

      // 2. Stop transaction
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

  // OCPP CallResult (Response from Backend)
  else if (messageTypeId === 3) {
    const payload = msg[2];
    console.log("📥 Received CallResult Response:", payload);

    // If it was a reply to BootNotification, start heartbeats
    if (payload.status === "Accepted" && !heartbeatTimer) {
      sendStatusNotification("Available");
      heartbeatTimer = setInterval(sendHeartbeat, HEARTBEAT_INTERVAL_MS);
    }

    // If it was a reply to StartTransaction, it returns the server's transactionId
    if (payload.transactionId && payload.idTagInfo && payload.idTagInfo.status === "Accepted") {
      currentTransactionId = payload.transactionId;
      console.log(`ℹ️ Session started with Backend TransactionID: ${currentTransactionId}`);
      
      // Start pushing live power data
      meterTimer = setInterval(sendMeterValues, METER_VALUE_INTERVAL_MS);
    }
  }
}

// Helper to generate UUIDs
function generateUniqueId() {
  return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
}

// Run connection
connect();
