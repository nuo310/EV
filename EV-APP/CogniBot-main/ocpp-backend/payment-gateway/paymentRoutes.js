/**
 * ============================================
 * CCAvenue Payment Routes
 * ============================================
 *
 * Mounts under /api/payment in the main server.
 *
 * Routes:
 *   POST   /api/payment/create           → Create order & return encRequest
 *   POST   /api/payment/response         → CCAvenue callback (encResp)
 *   GET    /api/payment/status/:orderId  → Check payment status
 */

const express = require("express");
const router = express.Router();

const {
  createPayment,
  handlePaymentResponse,
  getPaymentStatus,
  mockPaymentSuccess,
} = require("./paymentController");

/*
========================
CREATE PAYMENT ORDER
========================
Frontend calls this endpoint.
Receives: { amount, customerName, email, phone, userId, chargerId, kwh }
Returns:  { encRequest, access_code, actionUrl, orderId }
*/
router.post("/create", createPayment);

/*
========================
CCAVENUE CALLBACK
========================
CCAvenue redirects the browser here with encResp.
This route MUST accept URL-encoded form POST bodies.
*/
router.post("/response", handlePaymentResponse);

/*
========================
PAYMENT STATUS CHECK
========================
Frontend polls this to verify transaction state.
*/
router.get("/status/:orderId", getPaymentStatus);

/*
========================
MOCK SUCCESS (LOCALHOST)
========================
Frontend triggers this to simulate payment completion during local testing.
*/
router.post("/mock-success", mockPaymentSuccess);

module.exports = router;
