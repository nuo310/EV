import React from 'react';
import { RefreshCw, Coins, Calendar } from 'lucide-react';

export default function Refunds() {
  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 py-24 px-4 sm:px-6 lg:px-8 relative overflow-hidden">
      {/* Background patterns */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,rgba(16,185,129,0.08),transparent_50%)]" />
      <div className="absolute inset-0 bg-repeat opacity-5 dot-grid pointer-events-none" />

      <div className="max-w-4xl mx-auto relative z-10">
        {/* Header Section */}
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-emerald-500/30 bg-emerald-950/20 text-emerald-400 text-xs font-semibold mb-6 uppercase tracking-wider">
            <RefreshCw size={12} className="animate-spin-slow" />
            Fair Settlement
          </div>
          <h1 className="text-4xl sm:text-5xl font-black tracking-tight text-white mb-6">
            Refund & <span className="text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 to-green-500">Cancellation</span>
          </h1>
          <p className="text-lg text-slate-400 max-w-2xl mx-auto">
            Billing guidelines for failed transactions, aborted chargers, or session cancellations.
          </p>
        </div>

        {/* Detailed Guidelines */}
        <div className="backdrop-blur-md bg-slate-900/60 border border-slate-800/80 rounded-2xl p-8 mb-12 shadow-2xl space-y-8 text-slate-300">
          <section>
            <h2 className="text-xl font-bold text-white mb-3 flex items-center gap-2">
              <Coins size={20} className="text-emerald-400" /> 1. Cancel Active charging sessions
            </h2>
            <p className="leading-relaxed">
              Users can stop a charging session at any moment by clicking "Stop Charging" in their active card. The billing system automatically calculates the cost of electricity consumed up to that second based on the active meter readings (OCPP values). You are charged **only** for the energy delivered to your vehicle.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-white mb-3 flex items-center gap-2">
              <span className="text-emerald-400 font-mono">⚠️</span> 2. Failed Transactions & Charging Aborts
            </h2>
            <p className="leading-relaxed">
              If you initiate a payment but the charging connector fails to start (due to connectivity, grid power failure, or charger protocol handshakes):
            </p>
            <ul className="list-disc pl-5 mt-2 space-y-2 text-slate-400">
              <li>The billing system automatically flags the transaction for complete reversal.</li>
              <li>A direct refund process initiates within 24 hours of the failed event.</li>
              <li>Funds will credit back to your source payment method (card, bank account, or wallet) as per standard banking schedules.</li>
            </ul>
          </section>

          <section>
            <h2 className="text-xl font-bold text-white mb-3 flex items-center gap-2">
              <Calendar size={20} className="text-emerald-400" /> 3. Refund Timelines
            </h2>
            <p className="leading-relaxed">
              Upon confirmation of transaction cancellation, the refund processes through the CCAvenue gateway. The amount usually reflects in your credit card, debit card, or banking statement within **5 to 7 business days**, depending on the issuing bank's policies.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-white mb-3 flex items-center gap-2">
              <span className="text-emerald-400 font-mono">📋</span> 4. Refund Claims Support
            </h2>
            <p className="leading-relaxed">
              If your charging transaction failed and you have not received a credit confirmation after 7 working days, please email our support desk at <strong className="text-white">alliancesupport@ccavenue.com</strong> with your Transaction ID, User Email, and Charger ID to expedite processing.
            </p>
          </section>
        </div>

        {/* Corporate Info Footer */}
        <div className="border-t border-slate-800/80 pt-8 text-center text-xs text-slate-500">
          <p>Transparent billing. All transactions are fully audited.</p>
        </div>
      </div>
    </div>
  );
}
