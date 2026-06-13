const sendResponse = require("../utils/sendResponse");
const db = require("../firebase");

// Persistent transaction ID counter — bootstrapped from Firestore on first use
let nextOcppTransactionId = null;

async function getNextTransactionId() {
  if (nextOcppTransactionId === null) {
    try {
      const snap = await db.collection("transactions")
        .orderBy("ocppTransactionId", "desc")
        .limit(1)
        .get();
      const maxId = snap.empty ? 999 : (Number(snap.docs[0].data().ocppTransactionId) || 999);
      nextOcppTransactionId = maxId + 1;
      console.log(`🔢 Transaction ID counter bootstrapped from Firestore: starting at ${nextOcppTransactionId}`);
    } catch (err) {
      console.error("Failed to bootstrap transaction ID from Firestore, using fallback:", err);
      nextOcppTransactionId = Date.now(); // safe fallback — unique enough
    }
  }
  return nextOcppTransactionId++;
}

module.exports = async function handleRequest(
  ws,
  uniqueId,
  action,
  payload,
  chargePointId
) {

  switch (action) {

    // ===============================
    // BootNotification
    // ===============================
    case "BootNotification":

      console.log("BootNotification received:", payload);

      const stationRefBoot = db.collection("stations").doc(chargePointId);

      const stationDocBoot = await stationRefBoot.get();

      // No Firestore station doc until admin creates it (client/admin panel).
      const latVal = ws.latitude || 26.1443;
      const lngVal = ws.longitude || 91.7363;

      if (stationDocBoot.exists) {
        const updateData = {
          isOnline: true,
          status: "Available",
          lastSeen: new Date(),
          vendor: payload.chargePointVendor,
          model: payload.chargePointModel,
          websocketUrl: ws.connectionWsUrl || ""
        };
        if (ws.latitude && ws.longitude) {
          updateData.lat = ws.latitude;
          updateData.lng = ws.longitude;
        }
        await stationRefBoot.set(updateData, { merge: true });
      } else {
        console.log(
          "Auto-creating Firestore station for simulator testing:",
          chargePointId
        );
        await stationRefBoot.set({
          name: `Simulated Charger ${chargePointId}`,
          ocppStationId: chargePointId,
          lat: latVal,
          lng: lngVal,
          availableSlots: 1,
          pricePerHour: 15,
          energyRatePerKwh: 12,
          chargerType: "Type 2 AC",
          connectorId: 1,
          vendor: payload.chargePointVendor || "ZynkaTech Simulator",
          model: payload.chargePointModel || "Z-Model-S",
          status: "Available",
          errorCode: "NoError",
          isOnline: true,
          published: true,
          lastSeen: new Date(),
          websocketUrl: ws.connectionWsUrl || ""
        });
      }

      sendResponse(ws, uniqueId, {
        status: "Accepted",
        currentTime: new Date().toISOString(),
        interval: 60
      });

      break;



    // ===============================
    // Heartbeat
    // ===============================
    case "Heartbeat":

      console.log("Heartbeat received");

      const hbRef = db.collection("stations").doc(chargePointId);
      const hbSnap = await hbRef.get();
      if (hbSnap.exists) {
        await hbRef.set({ lastSeen: new Date() }, { merge: true });
      }

      sendResponse(ws, uniqueId, {
        currentTime: new Date().toISOString()
      });

      break;


    // ===============================
    // StatusNotification
    // ===============================
    case "StatusNotification":

      console.log("StatusNotification:", payload);

      const stationRef = db.collection("stations").doc(chargePointId);

      const stationDoc = await stationRef.get();

      if (stationDoc.exists) {
        await stationRef.set({
          status: payload.status,
          connectorId: payload.connectorId,
          errorCode: payload.errorCode,
          lastSeen: new Date()
        }, { merge: true });

        // If the status changes to Unavailable or Faulted, terminate active sessions
        const incomingStatus = (payload.status || "").toLowerCase();
        if (incomingStatus === "unavailable" || incomingStatus === "faulted") {
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
              console.log(`Terminated active transaction ${doc.id} (station status became ${payload.status}).`);
            }
          } catch (txErr) {
            console.error(`Failed to terminate active transactions for ${chargePointId} on status change:`, txErr);
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
              console.log(`Terminated active booking ${doc.id} (station status became ${payload.status}).`);
            }
          } catch (bkErr) {
            console.error(`Failed to terminate active bookings for ${chargePointId} on status change:`, bkErr);
          }
        }
      } else {
        console.log(
          "Skipping Firestore station status (not registered by admin yet):",
          chargePointId
        );
      }

      sendResponse(ws, uniqueId, {});

      break;


    // ===============================
    // Authorize
    // ===============================
    case "Authorize":

      console.log("Authorize received:", payload);

      sendResponse(ws, uniqueId, {
        idTagInfo: {
          status: "Accepted"
        }
      });

      break;


    // ===============================
    // StartTransaction
    // ===============================
    case "StartTransaction":

      console.log("StartTransaction received:", payload);

      const startStationSnap = await db.collection("stations").doc(chargePointId).get();
      if (!startStationSnap.exists) {
        console.log(
          "StartTransaction: station not registered by admin, rejecting:",
          chargePointId
        );
        sendResponse(ws, uniqueId, {
          transactionId: 0,
          idTagInfo: { status: "Invalid" }
        });
        break;
      }

      const ocppTransactionId = await getNextTransactionId();

      await db.collection("transactions")
        .add({
          stationId: chargePointId,
          ocppTransactionId,
          connectorId: payload.connectorId,
          userId: payload.idTag,
          meterStart: payload.meterStart,
          status: "active",
          timestamp: new Date()
        });

      sendResponse(ws, uniqueId, {
        transactionId: ocppTransactionId,
        idTagInfo: {
          status: "Accepted"
        }
      });

      break;


    // ===============================
    // StopTransaction
    // ===============================
    case "StopTransaction":

      console.log("StopTransaction received:", payload);

      const incomingTransactionId = Number(payload.transactionId);
      if (Number.isFinite(incomingTransactionId)) {
        const txSnap = await db.collection("transactions")
          .where("ocppTransactionId", "==", incomingTransactionId)
          .where("status", "==", "active")
          .limit(1)
          .get();

        const txDoc = txSnap.docs[0];
        if (txDoc) {
          await txDoc.ref.update({
            meterStop: payload.meterStop,
            status: "completed",
            endedAt: new Date()
          });
        }

        // Reset station status to Available after charging ends
        try {
          await db.collection("stations").doc(chargePointId).set({
            status: "Available",
            lastSeen: new Date()
          }, { merge: true });
        } catch (e) {
          console.error("Failed to reset station status after StopTransaction:", e);
        }
      }

      sendResponse(ws, uniqueId, {
        idTagInfo: {
          status: "Accepted"
        }
      });

      break;


    // ===============================
    // MeterValues
    // ===============================
    case "MeterValues":

      console.log("MeterValues:", payload);

      const mvStationRef = db.collection("stations").doc(chargePointId);
      const mvStationSnap = await mvStationRef.get();
      if (mvStationSnap.exists) {
        await db.collection("meterValues")
          .add({
            stationId: chargePointId,
            data: payload,
            timestamp: new Date()
          });
      }

      sendResponse(ws, uniqueId, {});

      break;


    // ===============================
    // Unknown message fallback
    // ===============================
    default:

      console.log("Unknown action:", action);

      sendResponse(ws, uniqueId, {});
  }

};