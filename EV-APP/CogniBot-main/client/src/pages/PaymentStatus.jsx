import React, { useEffect } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { CheckCircle2, XCircle, ArrowRight, Zap, Download, Calendar, MapPin, ReceiptText } from 'lucide-react';
import toast from 'react-hot-toast';

export default function PaymentStatus() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();

  const status = searchParams.get('status') || 'success';
  const amount = searchParams.get('amount') || '0.00';
  const kwh = searchParams.get('kwh') || '0.0';
  const stationName = searchParams.get('stationName') || 'EV Charger';
  const orderId = searchParams.get('orderId') || `TXN-${Math.floor(100000 + Math.random() * 900000)}`;
  const reason = searchParams.get('reason') || '';
  const dateStr = new Date().toLocaleString();

  const isSuccess = status === 'success';

  useEffect(() => {
    if (isSuccess) {
      toast.success('Charging session authorized successfully!');
    } else {
      toast.error(reason ? `Payment failed: ${reason}` : 'Payment authorization aborted or failed.');
    }
  }, [isSuccess, reason]);

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col items-center justify-center py-20 px-4 sm:px-6 relative overflow-hidden">
      {/* Background patterns */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(16,185,129,0.05),transparent_60%)]" />
      <div className="absolute inset-0 bg-repeat opacity-5 dot-grid pointer-events-none" />

      <div className="w-full max-w-md relative z-10">
        
        {/* Animated Status Container */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          className="backdrop-blur-md bg-slate-900/60 border border-slate-800 rounded-3xl p-8 shadow-2xl relative overflow-hidden text-center"
        >
          {/* Subtle top brand decoration */}
          <div className="absolute top-0 inset-x-0 h-1 bg-gradient-to-r from-emerald-500 to-green-400 opacity-60" />

          {/* Success / Failure Banner Icon */}
          <div className="flex justify-center mb-6">
            {isSuccess ? (
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: [0, 1.2, 1] }}
                transition={{ duration: 0.5 }}
                className="relative"
              >
                {/* Green Pulsing Ring */}
                <div className="absolute inset-0 rounded-full bg-emerald-500/20 animate-ping" />
                <div className="w-20 h-20 rounded-full bg-emerald-950/40 border-2 border-emerald-400 flex items-center justify-center text-emerald-400 relative z-10">
                  <CheckCircle2 size={44} />
                </div>
              </motion.div>
            ) : (
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: [0, 1.2, 1] }}
                transition={{ duration: 0.5 }}
                className="relative"
              >
                <div className="absolute inset-0 rounded-full bg-rose-500/20 animate-ping" />
                <div className="w-20 h-20 rounded-full bg-rose-950/40 border-2 border-rose-400 flex items-center justify-center text-rose-400 relative z-10">
                  <XCircle size={44} />
                </div>
              </motion.div>
            )}
          </div>

          {/* Status Label text */}
          <h1 className="text-3xl font-black mb-2 text-white">
            {isSuccess ? 'Payment Successful' : 'Payment Failed'}
          </h1>
          <p className="text-slate-400 text-sm mb-8">
            {isSuccess
              ? 'Your charging transaction has been authorized securely.'
              : reason 
                ? `Reason: ${reason}`
                : 'The gateway returned a failure response. No charges were made.'}
          </p>

          {/* Bill Receipt breakdown details */}
          <div className="bg-slate-950/60 border border-slate-850 rounded-2xl p-5 mb-8 text-left space-y-4">
            <div className="flex items-center gap-2 pb-3 border-b border-slate-800/80 text-xs font-bold text-slate-500 tracking-wider uppercase">
              <ReceiptText size={14} className="text-emerald-400" /> Transaction details
            </div>

            <div className="grid grid-cols-2 gap-y-3.5 text-xs">
              <div className="text-slate-500 font-semibold">Station Name</div>
              <div className="text-white font-bold text-right flex items-center justify-end gap-1.5">
                <MapPin size={12} className="text-emerald-400" /> {stationName}
              </div>

              <div className="text-slate-500 font-semibold">Energy Reserved</div>
              <div className="text-white font-bold text-right flex items-center justify-end gap-1">
                <Zap size={12} className="text-emerald-400 fill-emerald-400" /> {kwh} kWh
              </div>

              <div className="text-slate-500 font-semibold">Transaction ID</div>
              <div className="text-white font-mono font-bold text-right">{orderId}</div>

              <div className="text-slate-500 font-semibold">Authorization Date</div>
              <div className="text-slate-300 text-right flex items-center justify-end gap-1">
                <Calendar size={12} /> {dateStr}
              </div>

              <div className="col-span-2 border-t border-slate-800/80 my-2" />

              <div className="text-slate-400 font-bold text-sm">Amount Paid</div>
              <div className="text-emerald-400 font-black text-lg text-right">₹{amount}</div>
            </div>
          </div>

          {/* OCPP Connector startup confirmation */}
          {isSuccess && (
            <div className="bg-emerald-950/10 border border-emerald-500/20 rounded-2xl p-4 mb-8 text-left flex items-start gap-3">
              <Zap size={18} className="text-emerald-400 shrink-0 mt-0.5 animate-pulse" />
              <div>
                <p className="text-xs font-extrabold text-emerald-400 uppercase tracking-wider mb-0.5">OCPP Sync Active</p>
                <p className="text-[11px] text-slate-400 leading-normal">
                  RemoteStartCommand sent successfully to station connector. Please insert cable in your vehicle socket.
                </p>
              </div>
            </div>
          )}

          {/* Action buttons */}
          <div className="flex flex-col gap-3">
            <button
              onClick={() => navigate('/find-charger')}
              className="w-full bg-slate-800 hover:bg-slate-700 active:scale-[0.98] text-white font-bold py-3.5 px-4 rounded-xl border border-slate-700 transition-all flex items-center justify-center gap-2"
            >
              Return to Charger Finder <ArrowRight size={16} />
            </button>
            <button
              onClick={() => navigate('/dashboard')}
              className="w-full bg-emerald-500 hover:bg-emerald-600 active:scale-[0.98] text-slate-950 font-extrabold py-3.5 px-4 rounded-xl transition-all flex items-center justify-center gap-2 shadow-lg shadow-emerald-500/10"
            >
              View Dashboard Logs
            </button>
            {isSuccess && (
              <button
                onClick={() => window.print()}
                className="w-full bg-transparent hover:bg-slate-800/40 text-slate-400 hover:text-slate-200 text-xs font-semibold py-2 transition-all flex items-center justify-center gap-1.5"
              >
                <Download size={12} /> Download Invoice Receipt
              </button>
            )}
          </div>

        </motion.div>
      </div>
    </div>
  );
}
