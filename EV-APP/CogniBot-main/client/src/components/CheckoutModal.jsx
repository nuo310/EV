import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, ShieldCheck, CreditCard, Landmark, Smartphone, Zap, Loader2, Lock } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

export default function CheckoutModal({ isOpen, onClose, amount, kwh, rate, station, onPay }) {
  const { currentUser } = useAuth();
  const [activeTab, setActiveTab] = useState('card'); // card, netbanking, upi
  const [loading, setLoading] = useState(false);
  const [loadingStep, setLoadingStep] = useState(0); // 0: idle, 1: handshake, 2: gateway redirect
  const [email, setEmail] = useState(currentUser?.email || 'user@chargemap.in');
  const [phone, setPhone] = useState(currentUser?.profile?.phone || '+91 99887 76655');

  // Dummy inputs
  const [cardNumber, setCardNumber] = useState('');
  const [cardExpiry, setCardExpiry] = useState('');
  const [cardCvv, setCardCvv] = useState('');
  const [upiId, setUpiId] = useState('');
  const [selectedBank, setSelectedBank] = useState('');

  useEffect(() => {
    if (currentUser) {
      if (currentUser.email) setEmail(currentUser.email);
      if (currentUser.profile?.phone) setPhone(currentUser.profile.phone);
    }
  }, [currentUser]);

  if (!isOpen) return null;

  const tax = Math.round(amount * 0.18 * 100) / 100;
  const total = Math.round((amount + tax) * 100) / 100;

  const handlePaymentSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setLoadingStep(1);

    try {
      const backendUrl = import.meta.env.VITE_OCPP_REMOTE_START_BASE_URL || '/api';
      // If it ends with a slash, strip it
      const baseApiUrl = backendUrl.endsWith('/') ? backendUrl.slice(0, -1) : backendUrl;
      const createUrl = `${baseApiUrl}/payment/create`;

      const payload = {
        amount: total,
        customerName: currentUser?.displayName || currentUser?.profile?.name || 'EV Client',
        email: email,
        phone: phone,
        userId: currentUser?.uid || 'guest',
        chargerId: station?.ocppStationId || station?.id || 'unknown',
        stationName: station?.name || 'EV Charger',
        kwh: kwh,
      };

      console.log('Initiating payment request to:', createUrl, payload);

      const res = await fetch(createUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      if (!res.ok) {
        const errData = await res.json().catch(() => ({}));
        throw new Error(errData.error || 'Failed to create payment order');
      }

      const { encRequest, access_code, actionUrl } = await res.json();
      setLoadingStep(2);

      // Dynamically create a hidden form and submit it to redirect to CCAvenue
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = actionUrl;

      const encReqInput = document.createElement('input');
      encReqInput.type = 'hidden';
      encReqInput.name = 'encRequest';
      encReqInput.value = encRequest;
      form.appendChild(encReqInput);

      const accessCodeInput = document.createElement('input');
      accessCodeInput.type = 'hidden';
      accessCodeInput.name = 'access_code';
      accessCodeInput.value = access_code;
      form.appendChild(accessCodeInput);

      document.body.appendChild(form);
      console.log('Redirecting to CCAvenue payment page...');
      form.submit();
    } catch (err) {
      console.error('Payment initiation failed:', err);
      alert(err.message || 'Payment initiation failed. Please try again.');
      setLoading(false);
      setLoadingStep(0);
    }
  };

  const handleMockSubmit = async () => {
    setLoading(true);
    setLoadingStep(1);

    try {
      const backendUrl = import.meta.env.VITE_OCPP_REMOTE_START_BASE_URL || '/api';
      const baseApiUrl = backendUrl.endsWith('/') ? backendUrl.slice(0, -1) : backendUrl;
      const createUrl = `${baseApiUrl}/payment/create`;
      const mockSuccessUrl = `${baseApiUrl}/payment/mock-success`;

      // 1. Create payment order first
      const createPayload = {
        amount: total,
        customerName: currentUser?.displayName || currentUser?.profile?.name || 'EV Client',
        email: email,
        phone: phone,
        userId: currentUser?.uid || 'guest',
        chargerId: station?.ocppStationId || station?.id || 'unknown',
        stationName: station?.name || 'EV Charger',
        kwh: kwh,
      };

      const createRes = await fetch(createUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(createPayload),
      });

      if (!createRes.ok) {
        const errData = await createRes.json().catch(() => ({}));
        throw new Error(errData.error || 'Failed to create payment order');
      }

      const { orderId } = await createRes.json();
      setLoadingStep(2);

      // 2. Call mock success endpoint to trigger callback and get redirect URL
      const mockRes = await fetch(mockSuccessUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ orderId }),
      });

      if (!mockRes.ok) {
        const errData = await mockRes.json().catch(() => ({}));
        throw new Error(errData.error || 'Failed to process mock payment');
      }

      const { redirectUrl } = await mockRes.json();
      
      // Simulate redirection delay for good feel
      setTimeout(() => {
        window.location.href = redirectUrl;
      }, 1000);

    } catch (err) {
      console.error('Mock payment failed:', err);
      alert(err.message || 'Mock payment failed. Please try again.');
      setLoading(false);
      setLoadingStep(0);
    }
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-[10000] flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm">
        {/* Modal Window */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 20 }}
          className="w-full max-w-lg bg-slate-900 border border-slate-800 rounded-3xl overflow-hidden shadow-2xl relative"
        >
          {/* Header Panel */}
          <div className="bg-gradient-to-br from-slate-900 via-slate-950 to-slate-900 p-6 border-b border-slate-800 flex items-center justify-between relative">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-emerald-500 flex items-center justify-center border border-emerald-400/30 shadow-lg shadow-emerald-500/20">
                <Zap size={22} className="text-slate-950 fill-slate-950" />
              </div>
              <div>
                <h3 className="text-white font-extrabold text-lg tracking-tight">ChargeMap Pay</h3>
                <p className="text-[10px] text-slate-500 font-mono tracking-wider">MID: 4447763 (CCAvenue Staging)</p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="text-slate-400 hover:text-white hover:bg-slate-800 p-2 rounded-xl transition-colors"
            >
              <X size={18} />
            </button>
          </div>

          {/* Loader Overlay (Razorpay Handshake Style) */}
          {loading && (
            <div className="absolute inset-0 bg-slate-950/95 z-50 flex flex-col items-center justify-center p-6 text-center">
              <Loader2 className="animate-spin text-emerald-400 mb-6" size={48} />
              <h4 className="text-white font-bold text-lg mb-2">
                {loadingStep === 1 ? 'Securing Connection...' : 'Simulating Payment Response...'}
              </h4>
              <p className="text-sm text-slate-400 max-w-xs leading-relaxed">
                {loadingStep === 1 
                  ? 'Establishing encrypted AES-128 tunnel with CCAvenue servers.' 
                  : 'Receiving authorization response from Avenues Test portal.'}
              </p>
              <div className="mt-8 flex items-center gap-2 px-3 py-1 rounded-full border border-emerald-500/20 bg-emerald-950/20 text-emerald-400 text-xs">
                <ShieldCheck size={14} /> PCI-DSS Compliant Secure Session
              </div>
            </div>
          )}

          {/* Main Modal Body */}
          <form onSubmit={handlePaymentSubmit} className="p-6">
            
            {/* Bill Info Segment */}
            <div className="bg-slate-950/60 border border-slate-800/80 rounded-2xl p-5 mb-6 flex justify-between items-center">
              <div>
                <p className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1">Energy Requested</p>
                <p className="text-white font-extrabold text-xl">{kwh} kWh</p>
                <p className="text-xs text-slate-400">@ ₹{rate}/kWh for {station?.name}</p>
              </div>
              <div className="text-right">
                <p className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1">Amount Due</p>
                <p className="text-emerald-400 font-black text-2xl">₹{total}</p>
                <p className="text-[10px] text-slate-500">Includes 18% GST (₹{tax})</p>
              </div>
            </div>

            {/* Customer Details */}
            <div className="grid grid-cols-2 gap-4 mb-6">
              <div>
                <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1.5">Email Address</label>
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800/80 rounded-xl px-3 py-2 text-xs focus:outline-none focus:border-emerald-500 text-white"
                />
              </div>
              <div>
                <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1.5">Contact Number</label>
                <input
                  type="text"
                  required
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800/80 rounded-xl px-3 py-2 text-xs focus:outline-none focus:border-emerald-500 text-white"
                />
              </div>
            </div>

            {/* Payment Method Selector Tabs */}
            <div className="border-t border-slate-800 pt-6 mb-6">
              <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-3">Select Payment Method</label>
              <div className="grid grid-cols-3 gap-2 p-1 bg-slate-950 rounded-xl border border-slate-800/60">
                <button
                  type="button"
                  onClick={() => setActiveTab('card')}
                  className={`flex items-center justify-center gap-2 py-2.5 rounded-lg text-xs font-bold transition-all ${
                    activeTab === 'card' ? 'bg-slate-800 text-emerald-400 shadow-md' : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  <CreditCard size={14} /> Card
                </button>
                <button
                  type="button"
                  onClick={() => setActiveTab('netbanking')}
                  className={`flex items-center justify-center gap-2 py-2.5 rounded-lg text-xs font-bold transition-all ${
                    activeTab === 'netbanking' ? 'bg-slate-800 text-emerald-400 shadow-md' : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  <Landmark size={14} /> Net Banking
                </button>
                <button
                  type="button"
                  onClick={() => setActiveTab('upi')}
                  className={`flex items-center justify-center gap-2 py-2.5 rounded-lg text-xs font-bold transition-all ${
                    activeTab === 'upi' ? 'bg-slate-800 text-emerald-400 shadow-md' : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  <Smartphone size={14} /> UPI
                </button>
              </div>
            </div>

            {/* Tab Contents */}
            <div className="min-h-[140px] mb-6">
              {/* Card Payment */}
              {activeTab === 'card' && (
                <div className="space-y-4">
                  <div>
                    <input
                      type="text"
                      placeholder="Card Number"
                      required={activeTab === 'card'}
                      value={cardNumber}
                      onChange={(e) => setCardNumber(e.target.value)}
                      className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-3 text-sm text-white placeholder-slate-600 focus:outline-none focus:border-emerald-500"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <input
                      type="text"
                      placeholder="MM / YY"
                      required={activeTab === 'card'}
                      value={cardExpiry}
                      onChange={(e) => setCardExpiry(e.target.value)}
                      className="bg-slate-950 border border-slate-800 rounded-xl px-4 py-3 text-sm text-white placeholder-slate-600 focus:outline-none focus:border-emerald-500 text-center"
                    />
                    <input
                      type="password"
                      placeholder="CVV"
                      maxLength={3}
                      required={activeTab === 'card'}
                      value={cardCvv}
                      onChange={(e) => setCardCvv(e.target.value)}
                      className="bg-slate-950 border border-slate-800 rounded-xl px-4 py-3 text-sm text-white placeholder-slate-600 focus:outline-none focus:border-emerald-500 text-center"
                    />
                  </div>
                </div>
              )}

              {/* Net Banking */}
              {activeTab === 'netbanking' && (
                <div className="space-y-3">
                  <select
                    required={activeTab === 'netbanking'}
                    value={selectedBank}
                    onChange={(e) => setSelectedBank(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-emerald-500"
                  >
                    <option value="">Choose Bank</option>
                    <option value="avenues">Avenues Test Netbanking (Staging)</option>
                    <option value="hdfc" disabled>HDFC Bank (Needs Bank Approval)</option>
                    <option value="icici" disabled>ICICI Bank (Needs Bank Approval)</option>
                    <option value="sbi" disabled>SBI Netbanking (Needs Bank Approval)</option>
                  </select>
                  <p className="text-[10px] text-amber-500 leading-normal bg-amber-950/20 border border-amber-900/30 p-3 rounded-lg">
                    * Note: To process test transactions, select <strong>Avenues Test Netbanking</strong>. All commercial banks require live production approvals.
                  </p>
                </div>
              )}

              {/* UPI */}
              {activeTab === 'upi' && (
                <div className="space-y-4">
                  <input
                    type="text"
                    placeholder="Enter UPI ID (e.g. user@okaxis)"
                    required={activeTab === 'upi'}
                    value={upiId}
                    onChange={(e) => setUpiId(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-3 text-sm text-white placeholder-slate-600 focus:outline-none focus:border-emerald-500"
                  />
                  <div className="text-center">
                    <span className="text-xs text-slate-500">OR pay with QR Code</span>
                    <div className="mx-auto mt-3 w-28 h-28 bg-white p-2 rounded-xl flex items-center justify-center shadow-lg">
                      <div className="w-full h-full border-4 border-slate-900 border-dashed flex items-center justify-center text-slate-900 font-bold text-[8px]">QR MOCK</div>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              className="w-full bg-emerald-500 hover:bg-emerald-600 active:scale-[0.98] text-slate-950 font-extrabold py-3.5 px-4 rounded-2xl transition-all shadow-lg shadow-emerald-500/10 flex items-center justify-center gap-2 mb-3"
            >
              <Lock size={16} /> Pay ₹{total} securely via CCAvenue
            </button>

            {/* Local Host bypass simulator button */}
            {(window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') && (
              <button
                type="button"
                onClick={handleMockSubmit}
                className="w-full bg-amber-500/10 hover:bg-amber-500/20 text-amber-400 border border-amber-500/30 font-bold py-2.5 px-4 rounded-xl transition-all flex items-center justify-center gap-1.5 text-xs mb-3"
              >
                <Zap size={14} className="animate-pulse" /> Simulate Local Sandbox Success (Bypass Whitelist)
              </button>
            )}
            
            <div className="mt-4 flex items-center justify-center gap-1.5 text-[10px] text-slate-500 font-semibold uppercase tracking-wider">
              <ShieldCheck size={14} className="text-emerald-500" /> Fully Secured 128-bit Encrypted Gateways
            </div>
          </form>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
