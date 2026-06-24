import React from 'react';
import { motion } from 'framer-motion';
import { Zap, Shield, Cpu, Users, Award } from 'lucide-react';

export default function About() {
  return (
    <div className="min-h-screen bg-slate-50 text-slate-800 py-24 px-4 sm:px-6 lg:px-8 relative overflow-hidden">
      {/* Background patterns */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,rgba(16,185,129,0.06),transparent_50%)]" />
      <div className="absolute inset-0 bg-repeat opacity-[0.03] dot-grid pointer-events-none" />

      <div className="max-w-4xl mx-auto relative z-10">
        {/* Header Section */}
        <div className="text-center mb-16">
          {/* <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-emerald-200 bg-emerald-50 text-emerald-700 text-xs font-semibold mb-6 uppercase tracking-wider">
            <Zap size={12} className="animate-pulse" />
            Infrastructure Intelligence
          </div> */}
          <h1 className="text-4xl sm:text-5xl font-black tracking-tight text-slate-900 mt-4 mb-6">
            About <span className="text-transparent bg-clip-text bg-gradient-to-r from-emerald-600 to-green-600">EV Charge</span>
          </h1>
          <p className="text-lg text-slate-600 max-w-2xl mx-auto">
            Powering the transition to electric mobility with next-generation high-speed OCPP integrated charging software.
          </p>
        </div>

        {/* Brand Mission Card */}
        <div className="backdrop-blur-md bg-white border border-slate-200/80 rounded-2xl p-8 mb-12 shadow-xl relative overflow-hidden">
          <div className="absolute top-0 right-0 w-32 h-32 bg-emerald-500/5 rounded-full blur-3xl pointer-events-none" />
          <h2 className="text-2xl font-bold text-slate-900 mb-4 flex items-center gap-3">
            <Award className="text-emerald-600" /> Our Mission
          </h2>
          <p className="text-slate-600 leading-relaxed mb-6">
            EV Charge is dedicated to designing, building, and operating the most reliable EV charging terminal. We bridge the gap between complex OCPP hardware communications and consumer payment workflows, delivering a seamless charging experience for every EV owner in India.
          </p>
          <p className="text-slate-600 leading-relaxed">
            By deploying cutting-edge telemetry networks and smart scheduling algorithms, we ensure high station availability, dynamic queue routing, and robust transaction security.
          </p>
        </div>

        {/* Feature Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-16">
          <div className="backdrop-blur-sm bg-white/80 border border-slate-200/80 rounded-xl p-6 hover:border-emerald-50 hover:shadow-md transition-all">
            <div className="w-12 h-12 rounded-lg bg-emerald-50 border border-emerald-200/60 flex items-center justify-center text-emerald-600 mb-4">
              <Cpu size={24} />
            </div>
            <h3 className="text-lg font-bold text-slate-900 mb-2">OCPP 1.6 Protocol</h3>
            <p className="text-slate-600 text-sm leading-relaxed">
              Direct connection with physical hardware using secure websocket pathways for instant telemetry syncing.
            </p>
          </div>

          <div className="backdrop-blur-sm bg-white/80 border border-slate-200/80 rounded-xl p-6 hover:border-emerald-50 hover:shadow-md transition-all">
            <div className="w-12 h-12 rounded-lg bg-emerald-50 border border-emerald-200/60 flex items-center justify-center text-emerald-600 mb-4">
              <Shield size={24} />
            </div>
            <h3 className="text-lg font-bold text-slate-900 mb-2">Secure Transactions</h3>
            <p className="text-slate-600 text-sm leading-relaxed">
              Compliant integration patterns ensuring fully encrypted merchant handshakes and immediate transaction logging.
            </p>
          </div>

          <div className="backdrop-blur-sm bg-white/80 border border-slate-200/80 rounded-xl p-6 hover:border-emerald-50 hover:shadow-md transition-all">
            <div className="w-12 h-12 rounded-lg bg-emerald-50 border border-emerald-200/60 flex items-center justify-center text-emerald-600 mb-4">
              <Users size={24} />
            </div>
            <h3 className="text-lg font-bold text-slate-900 mb-2">Unified Network</h3>
            <p className="text-slate-600 text-sm leading-relaxed">
              Connecting fleet operations, private chargers, and public hubs under a unified dashboard.
            </p>
          </div>
        </div>

        {/* Corporate Info Footer */}

      </div>
    </div>
  );
}
