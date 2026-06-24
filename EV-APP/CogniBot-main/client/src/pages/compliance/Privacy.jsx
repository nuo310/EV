import React from 'react';
import { Eye, ShieldCheck, Database, Key, Lock } from 'lucide-react';

export default function Privacy() {
  return (
    <div className="min-h-screen bg-slate-50 text-slate-800 py-24 px-4 sm:px-6 lg:px-8 relative overflow-hidden">
      {/* Background patterns */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,rgba(16,185,129,0.06),transparent_50%)]" />
      <div className="absolute inset-0 bg-repeat opacity-[0.03] dot-grid pointer-events-none" />

      <div className="max-w-4xl mx-auto relative z-10">
        {/* Header Section */}
        <div className="text-center mb-16">
          {/* <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-emerald-200 bg-emerald-50 text-emerald-700 text-xs font-semibold mb-6 uppercase tracking-wider">
            <ShieldCheck size={12} />
            Data Protection
          </div> */}
          <h1 className="text-4xl sm:text-5xl font-black tracking-tight text-slate-900 mb-6 mt-4">
            Privacy <span className="text-transparent bg-clip-text bg-gradient-to-r from-emerald-600 to-green-600">Policy</span>
          </h1>
          <p className="text-lg text-slate-600 max-w-2xl mx-auto">
            Your privacy is our priority. Learn how we handle your registration details, telemetry metrics, and financial information.
          </p>
        </div>

        {/* Detailed Policy */}
        <div className="backdrop-blur-md bg-white border border-slate-200/80 rounded-2xl p-8 mb-12 shadow-xl space-y-8 text-slate-600">
          <section>
            <h2 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
              <Database size={20} className="text-emerald-600" /> 1. Information We Collect
            </h2>
            <p className="leading-relaxed mb-4">
              We gather information to offer premium telemetry and charging solutions. This includes:
            </p>
            <ul className="list-disc pl-5 space-y-2 text-slate-500">
              <li><strong>Personal Data</strong>: Name, email address, mobile number, and charging history.</li>
              <li><strong>Device & Location Data</strong>: GPS coordinates of your vehicle or device to route you to nearby chargers.</li>
              <li><strong>Telemetry logs</strong>: Kilowatt usage, start/stop values, and voltage metrics synced via OCPP.</li>
            </ul>
          </section>

          <section>
            <h2 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
              <Key size={20} className="text-emerald-600" /> 2. Secure Processing of Payments
            </h2>
            <p className="leading-relaxed">
              We do not store your credit card digits, UPI PINs, or net banking passwords. Financial details are transmitted directly to the secure gateway servers in encrypted form. The gateway performs transaction validations according to PCI-DSS rules.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
              <Eye size={20} className="text-emerald-600" /> 3. Data Share and Disclosures
            </h2>
            <p className="leading-relaxed">
              We never sell or rent your personal metrics. Charging telemetry and location profiles are shared exclusively with the station owners to ensure seamless charger connectivity and session billing processing.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
              <Lock size={20} className="text-emerald-600" /> 4. Protection and Retention
            </h2>
            <p className="leading-relaxed">
              We secure data using standard firewalls and secure token models (e.g. Firebase Authentications). Accounts and transaction logs are maintained as required to satisfy Indian compliance frameworks.
            </p>
          </section>
        </div>

        {/* Corporate Info Footer */}
        <div className="border-t border-slate-200/80 pt-8 text-center text-xs text-slate-500">
          <p>Secure transactions, global certifications. ChargeMap Security Team.</p>
        </div>
      </div>
    </div>
  );
}
