import React from 'react';
import { ShieldAlert, BookOpen, Scale, Zap, IndianRupee } from 'lucide-react';

export default function Terms() {
  return (
    <div className="min-h-screen bg-slate-50 text-slate-800 py-24 px-4 sm:px-6 lg:px-8 relative overflow-hidden">
      {/* Background patterns */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,rgba(16,185,129,0.06),transparent_50%)]" />
      <div className="absolute inset-0 bg-repeat opacity-[0.03] dot-grid pointer-events-none" />

      <div className="max-w-4xl mx-auto relative z-10">
        {/* Header Section */}
        <div className="text-center mb-16">
          <h1 className="text-4xl sm:text-5xl font-black tracking-tight text-slate-900 mt-4 mb-6">
            Terms & <span className="text-transparent bg-clip-text bg-gradient-to-r from-emerald-600 to-green-600">Conditions</span>
          </h1>
          <p className="text-lg text-slate-600 max-w-2xl mx-auto">
            Last Updated: June 4, 2026. Please read these terms carefully before utilizing our charging platform services.
          </p>
        </div>

        {/* Detailed Agreement */}
        <div className="backdrop-blur-md bg-white border border-slate-200/80 rounded-2xl p-8 mb-12 shadow-xl space-y-8 text-slate-600">
          <section>
            <h2 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
              <BookOpen size={20} className="text-emerald-600" /> 1. Acceptance of Terms
            </h2>
            <p className="leading-relaxed">
              By registering an account and accessing the EV Charge application or using any of our EV charging services, you agree to comply with and be bound by these Terms and Conditions. If you do not agree, please do not use the services.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
              <ShieldAlert size={20} className="text-emerald-600" /> 2. Registration and Account Security
            </h2>
            <p className="leading-relaxed">
              To start charging, users must register an account providing accurate profile details. You are responsible for keeping your login information confidential and for all activities that occur under your account. We reserve the right to suspend accounts violating safety rules.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
              <IndianRupee size={20} className="text-emerald-600" /> 3. Pricing and Billing
            </h2>
            <ul className="list-disc pl-5 space-y-2 leading-relaxed text-slate-500">
              <li>Our charging services are priced dynamically based on consumption (measured in kilowatt-hours, or kWh).</li>
              <li>The exact rate per kWh is visible on each station details card before commencing a session.</li>
              <li>Transactions are handled securely through integrated gateway channels. Billing happens based on the kilowatt-hour value requested or consumed.</li>
              <li>Standard pricing includes base charging fees, dynamic station electricity costs, and applicable taxes.</li>
            </ul>
          </section>

          <section>
            <h2 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
              <Zap size={20} className="text-emerald-600" /> 4. Use of Charging Stations
            </h2>
            <p className="leading-relaxed">
              You agree to use our network stations safely and in accordance with manufacturer guidelines. Users are liable for any damages caused to station hardware, connectors, or cables due to negligent or unauthorized handling.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
              <Scale size={20} className="text-emerald-600" /> 5. Liability & Governing Law
            </h2>
            <p className="leading-relaxed">
              These terms are governed by and construed in accordance with the laws of India. EV Charge shall not be liable for damages to electric vehicles, batteries, or property during power fluctuations, grid changes, or due to third-party charger hardware errors.
            </p>
          </section>
        </div>

        {/* Corporate Info Footer */}
        <div className="border-t border-slate-200/80 pt-8 text-center text-xs text-slate-500">
          <p>If you have any questions regarding our terms, contact alliancesupport@ccavenue.com.</p>
        </div>
      </div>
    </div>
  );
}
