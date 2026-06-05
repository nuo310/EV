/**
 * ============================================
 * CCAvenue Payment Controller
 * ============================================
 *
 * Business logic for:
 *   1. Creating a payment order (encrypt & return encRequest)
 *   2. Handling the CCAvenue callback (decrypt encResp)
 *   3. Updating Firestore payment records
 *   4. Triggering OCPP RemoteStartTransaction on success
 */

const { v4: uuidv4 } = require("uuid");
const db = require("../firebase");
const { encrypt, decrypt, toQueryString, parseQueryString } = require("./ccavenueCrypto");

// ─── Environment ────────────────────────────────────────
const MERCHANT_ID   = process.env.CCAVENUE_MERCHANT_ID ? process.env.CCAVENUE_MERCHANT_ID.trim() : "";
const ACCESS_CODE   = process.env.CCAVENUE_ACCESS_CODE ? process.env.CCAVENUE_ACCESS_CODE.trim() : "";
const WORKING_KEY   = process.env.CCAVENUE_WORKING_KEY ? process.env.CCAVENUE_WORKING_KEY.trim() : "";
const REDIRECT_URL  = process.env.CCAVENUE_REDIRECT_URL;
const CANCEL_URL    = process.env.CCAVENUE_CANCEL_URL;
const FRONTEND_URL  = process.env.FRONTEND_URL || "http://localhost:5173";
const CCAVENUE_URL  = process.env.CCAVENUE_API_URL || "https://test.ccavenue.com/transaction/transaction.do?command=initiateTransaction";

/**
 * POST /api/payment/create
 *
 * Called by the React frontend when the user confirms
 * their kWh selection and clicks "Pay".
 *
 * Body: { amount, customerName, email, phone, userId, chargerId, kwh }
 *
 * Returns: { encRequest, access_code, actionUrl, orderId }
 */
async function createPayment(req, res) {
  try {
    const {
      amount,
      customerName,
      email,
      phone,
      userId,
      chargerId,
      stationName,
      kwh,
    } = req.body;

    // ── Validation ──────────────────────────────────────
    if (!amount || !email) {
      return res.status(400).json({ error: "amount and email are required" });
    }

    // ── Generate unique order ID ────────────────────────
    const orderId = `CM-${Date.now()}-${uuidv4().slice(0, 8).toUpperCase()}`;

    // ── Persist payment record in Firestore (PENDING) ───
    const paymentRef = db.collection("payments").doc(orderId);
    await paymentRef.set({
      orderId,
      userId:        userId || null,
      chargerId:     chargerId || null,
      stationName:   stationName || null,
      kwh:           kwh || null,
      amount:        Number(amount),
      currency:      "INR",
      status:        "PENDING",
      transactionId: null,
      trackingId:    null,
      bankRefNo:     null,
      failureReason: null,
      createdAt:     new Date().toISOString(),
      updatedAt:     new Date().toISOString(),
    });

    console.log(`💰 Payment record created: ${orderId}  ₹${amount}`);

    // ── Build CCAvenue request parameters ───────────────
    const requestParams = {
      merchant_id:   MERCHANT_ID,
      order_id:      orderId,
      currency:      "INR",
      amount:        String(amount),
      redirect_url:  REDIRECT_URL,
      cancel_url:    CANCEL_URL,
      language:      "EN",
      billing_name:  customerName || "",
      billing_email: email,
      billing_tel:   phone || "",
      // Merchant-defined fields (available in callback)
      merchant_param1: userId || "",
      merchant_param2: chargerId || "",
      merchant_param3: String(kwh || ""),
      merchant_param4: stationName || "",
    };

    // ── Encrypt ─────────────────────────────────────────
    const queryString = toQueryString(requestParams);
    const encRequest  = encrypt(queryString, WORKING_KEY);

    // ── Return encrypted payload to frontend ────────────
    return res.json({
      encRequest,
      access_code: ACCESS_CODE,
      actionUrl:   CCAVENUE_URL,
      orderId,
    });

  } catch (err) {
    console.error("❌ createPayment error:", err);
    return res.status(500).json({ error: "Failed to create payment" });
  }
}

/**
 * POST /api/payment/response
 *
 * CCAvenue redirects the user's browser here after payment.
 * The body contains an `encResp` field (URL-encoded form POST).
 *
 * We decrypt, parse, update Firestore, and redirect the user
 * to the frontend success/failure page.
 */
async function handlePaymentResponse(req, res) {
  try {
    const encResp = req.body.encResp;

    if (!encResp) {
      console.error("❌ No encResp received from CCAvenue");
      return res.redirect(`${FRONTEND_URL}/payment-status?status=failure&reason=no_response`);
    }

    // ── Decrypt ─────────────────────────────────────────
    const decrypted   = decrypt(encResp, WORKING_KEY);
    const paymentData = parseQueryString(decrypted);

    console.log("📦 CCAvenue Decrypted Response:", JSON.stringify(paymentData, null, 2));

    // ── Extract fields ──────────────────────────────────
    const orderId      = paymentData.order_id;
    const orderStatus  = paymentData.order_status;       // Success | Failure | Aborted | Invalid
    const trackingId   = paymentData.tracking_id  || null;
    const bankRefNo    = paymentData.bank_ref_no  || null;
    const amount       = paymentData.amount       || "0";
    const failureMsg   = paymentData.failure_message || paymentData.status_message || null;
    const userId       = paymentData.merchant_param1 || null;
    const chargerId    = paymentData.merchant_param2 || null;
    const kwh          = paymentData.merchant_param3 || null;
    const stationName  = paymentData.merchant_param4 || chargerId || "EV Charger";

    // ── Update Firestore payment record ─────────────────
    const paymentRef = db.collection("payments").doc(orderId);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      console.error(`❌ Payment record not found for order: ${orderId}`);
      return res.redirect(`${FRONTEND_URL}/payment-status?status=failure&reason=order_not_found`);
    }

    const updateData = {
      status:        orderStatus === "Success" ? "SUCCESS" : orderStatus === "Aborted" ? "ABORTED" : "FAILED",
      transactionId: trackingId,
      trackingId,
      bankRefNo,
      failureReason: orderStatus !== "Success" ? failureMsg : null,
      updatedAt:     new Date().toISOString(),
      rawResponse:   paymentData,
    };

    await paymentRef.update(updateData);
    console.log(`📝 Payment ${orderId} updated → ${updateData.status}`);

    // ── Handle Success ──────────────────────────────────
    if (orderStatus === "Success") {

      // Create a booking record in Firestore
      if (userId && chargerId) {
        try {
          const bookingRef = db.collection("bookings").doc();
          await bookingRef.set({
            userId,
            stationId:    chargerId,
            stationName:  stationName,
            connectorId:  1,
            status:       "active",
            createdAt:    new Date(),
            startedAt:    new Date(),
            meterStartWh: 0,
            kwhRequested: Number(kwh) || 0,
            paidAmount:   Number(amount),
            paymentOrderId: orderId,
            paymentTrackingId: trackingId,
          });
          console.log(`✅ Booking created for user ${userId} at station ${chargerId}`);
        } catch (bookingErr) {
          console.error("❌ Failed to create booking:", bookingErr);
        }

        // Trigger OCPP remote-start transaction directly in backend (simulating device power-up)
        try {
          const remoteStartUrl = `http://localhost:${process.env.PORT || 9221}/remote-start`;
          console.log(`Sending remote start request to: ${remoteStartUrl}`);
          
          // Using global fetch (available in modern Node.js)
          const remoteStartRes = await fetch(remoteStartUrl, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              stationId: chargerId,
            }),
          });
          const remoteStartResult = await remoteStartRes.json();
          console.log("Remote start response:", remoteStartResult);
        } catch (remoteStartErr) {
          console.error("❌ Failed to trigger RemoteStartTransaction from payment controller:", remoteStartErr);
        }
      }

      // Redirect to frontend success page
      return res.redirect(
        `${FRONTEND_URL}/payment-status?status=success` +
        `&amount=${encodeURIComponent(amount)}` +
        `&kwh=${encodeURIComponent(kwh || "0")}` +
        `&stationName=${encodeURIComponent(stationName)}` +
        `&stationId=${encodeURIComponent(chargerId || "")}` +
        `&orderId=${encodeURIComponent(orderId)}` +
        `&trackingId=${encodeURIComponent(trackingId || "")}`
      );
    }

    // ── Handle Failure / Aborted ────────────────────────
    return res.redirect(
      `${FRONTEND_URL}/payment-status?status=failure` +
      `&orderId=${encodeURIComponent(orderId)}` +
      `&reason=${encodeURIComponent(failureMsg || orderStatus)}`
    );

  } catch (err) {
    console.error("❌ handlePaymentResponse error:", err);
    return res.redirect(`${FRONTEND_URL}/payment-status?status=failure&reason=server_error`);
  }
}

/**
 * GET /api/payment/status/:orderId
 *
 * Allows the frontend to poll or check the status of a
 * specific payment order.
 */
async function getPaymentStatus(req, res) {
  try {
    const { orderId } = req.params;

    const paymentDoc = await db.collection("payments").doc(orderId).get();

    if (!paymentDoc.exists) {
      return res.status(404).json({ error: "Payment not found" });
    }

    const data = paymentDoc.data();

    return res.json({
      orderId:       data.orderId,
      status:        data.status,
      amount:        data.amount,
      currency:      data.currency,
      transactionId: data.transactionId,
      trackingId:    data.trackingId,
      bankRefNo:     data.bankRefNo,
      createdAt:     data.createdAt,
      updatedAt:     data.updatedAt,
    });

  } catch (err) {
    console.error("❌ getPaymentStatus error:", err);
    return res.status(500).json({ error: "Failed to fetch payment status" });
  }
}

/**
 * POST /api/payment/mock-success
 *
 * For local testing on localhost. Simulates a successful callback from CCAvenue
 * without needing to hit the external whitelisted gateway.
 *
 * Body: { orderId }
 */
async function mockPaymentSuccess(req, res) {
  try {
    const { orderId } = req.body;

    if (!orderId) {
      return res.status(400).json({ error: "orderId is required" });
    }

    const paymentRef = db.collection("payments").doc(orderId);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      return res.status(404).json({ error: "Payment record not found" });
    }

    const paymentData = paymentDoc.data();
    if (paymentData.status !== "PENDING") {
      return res.status(400).json({ error: "Payment is already processed" });
    }

    const trackingId = `MOCK-TRK-${Date.now()}`;
    const bankRefNo  = `MOCK-BNK-${Math.floor(100000 + Math.random() * 900000)}`;

    const updateData = {
      status:        "SUCCESS",
      transactionId: trackingId,
      trackingId,
      bankRefNo,
      failureReason: null,
      updatedAt:     new Date().toISOString(),
      rawResponse:   { isMock: true, status: "Success" },
    };

    await paymentRef.update(updateData);
    console.log(`📝 [Mock] Payment ${orderId} updated → SUCCESS`);

    // Create a booking record in Firestore
    const userId = paymentData.userId;
    const chargerId = paymentData.chargerId;
    const kwh = paymentData.kwh;
    const amount = paymentData.amount;
    const stationName = paymentData.stationName || chargerId || "EV Charger";

    if (userId && chargerId) {
      try {
        const bookingRef = db.collection("bookings").doc();
        await bookingRef.set({
          userId,
          stationId:    chargerId,
          stationName:  stationName,
          connectorId:  1,
          status:       "active",
          createdAt:    new Date(),
          startedAt:    new Date(),
          meterStartWh: 0,
          kwhRequested: Number(kwh) || 0,
          paidAmount:   Number(amount),
          paymentOrderId: orderId,
          paymentTrackingId: trackingId,
        });
        console.log(`✅ [Mock] Booking created for user ${userId} at station ${chargerId}`);
      } catch (bookingErr) {
        console.error("❌ [Mock] Failed to create booking:", bookingErr);
      }

      // Trigger OCPP remote-start transaction directly in backend (simulating device power-up)
      try {
        const remoteStartUrl = `http://localhost:${process.env.PORT || 9221}/remote-start`;
        console.log(`[Mock] Sending remote start request to: ${remoteStartUrl}`);
        
        const remoteStartRes = await fetch(remoteStartUrl, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            stationId: chargerId,
          }),
        });
        const remoteStartResult = await remoteStartRes.json();
        console.log("[Mock] Remote start response:", remoteStartResult);
      } catch (remoteStartErr) {
        console.error("❌ [Mock] Failed to trigger RemoteStartTransaction from payment controller:", remoteStartErr);
      }
    }

    return res.json({
      success: true,
      redirectUrl: `${FRONTEND_URL}/payment-status?status=success` +
        `&amount=${encodeURIComponent(amount)}` +
        `&kwh=${encodeURIComponent(kwh || "0")}` +
        `&stationName=${encodeURIComponent(stationName)}` +
        `&stationId=${encodeURIComponent(chargerId || "")}` +
        `&orderId=${encodeURIComponent(orderId)}` +
        `&trackingId=${encodeURIComponent(trackingId || "")}`
    });

  } catch (err) {
    console.error("❌ mockPaymentSuccess error:", err);
    return res.status(500).json({ error: "Failed to process mock success" });
  }
}

module.exports = {
  createPayment,
  handlePaymentResponse,
  getPaymentStatus,
  mockPaymentSuccess,
};
