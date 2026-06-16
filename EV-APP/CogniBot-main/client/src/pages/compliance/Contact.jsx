import React from 'react';
import { Mail, Phone, MapPin, Clock, Headset } from 'lucide-react';

export default function Contact() {
  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 py-24 px-4 sm:px-6 lg:px-8 relative overflow-hidden">
      {/* Background patterns */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,rgba(16,185,129,0.08),transparent_50%)]" />
      <div className="absolute inset-0 bg-repeat opacity-5 dot-grid pointer-events-none" />

      <div className="max-w-4xl mx-auto relative z-10">
        {/* Header Section */}
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-emerald-500/30 bg-emerald-950/20 text-emerald-400 text-xs font-semibold mb-6 uppercase tracking-wider">
            <Headset size={12} />
            Support Center
          </div>
          <h1 className="text-4xl sm:text-5xl font-black tracking-tight text-white mb-6">
            Contact <span className="text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 to-green-500">Us</span>
          </h1>
          <p className="text-lg text-slate-400 max-w-2xl mx-auto">
            Get in touch with our team for technical assistance, billing issues, or fleet collaborations.
          </p>
        </div>

        {/* Contact Info Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-12">
          {/* Contact Details Card */}
          <div className="backdrop-blur-md bg-slate-900/60 border border-slate-800/80 rounded-2xl p-8 shadow-2xl relative overflow-hidden">
            <h2 className="text-2xl font-bold text-white mb-6">Corporate Office</h2>
            
            <div className="space-y-6">
              <div className="flex items-start gap-4">
                <div className="w-10 h-10 rounded-lg bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-center text-emerald-400 shrink-0">
                  <MapPin size={20} />
                </div>
                <div>
                  <h3 className="font-semibold text-white mb-1">Registered Address (India)</h3>
                  <p className="text-slate-400 text-sm leading-relaxed">
                    EV Charge Terminal Solutions Private Limited<br />
                    SF-210, Synergy Business Park, Sahakar Marg,<br />
                    Lalkothi, Jaipur, Rajasthan - 302015, India
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-4">
                <div className="w-10 h-10 rounded-lg bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-center text-emerald-400 shrink-0">
                  <Mail size={20} />
                </div>
                <div>
                  <h3 className="font-semibold text-white mb-1">Email Queries</h3>
                  <p className="text-slate-400 text-sm">
                    Support: alliancesupport@ccavenue.com<br />
                    Enquiries: support@evcharge.in
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-4">
                <div className="w-10 h-10 rounded-lg bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-center text-emerald-400 shrink-0">
                  <Phone size={20} />
                </div>
                <div>
                  <h3 className="font-semibold text-white mb-1">Contact Phone</h3>
                  <p className="text-slate-400 text-sm">
                    +91 141 405 8922<br />
                    Toll-Free: 1800-210-9988
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-4">
                <div className="w-10 h-10 rounded-lg bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-center text-emerald-400 shrink-0">
                  <Clock size={20} />
                </div>
                <div>
                  <h3 className="font-semibold text-white mb-1">Service Hours</h3>
                  <p className="text-slate-400 text-sm">
                    Monday - Saturday: 09:00 AM - 06:00 PM IST
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Quick Support Ticket Box */}
          <div className="backdrop-blur-md bg-slate-900/60 border border-slate-800/80 rounded-2xl p-8 shadow-2xl flex flex-col justify-between">
            <div>
              <h2 className="text-2xl font-bold text-white mb-4">Direct Enquiry</h2>
              <p className="text-slate-400 text-sm leading-relaxed mb-6">
                Fill out your details to submit a diagnostic log or request hardware checks at your charging hub.
              </p>
              
              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">Subject</label>
                  <input type="text" placeholder="Billing query / Charger failure" className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:border-emerald-500 text-white" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">Message</label>
                  <textarea rows="4" placeholder="Detail your problem..." className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:border-emerald-500 text-white resize-none"></textarea>
                </div>
              </div>
            </div>

            <button className="w-full mt-6 bg-emerald-500 hover:bg-emerald-600 active:scale-95 text-slate-950 font-bold py-3 rounded-xl transition-all shadow-lg shadow-emerald-500/20">
              Submit Ticket
            </button>
          </div>
        </div>

        {/* Corporate Info Footer */}
        <div className="border-t border-slate-800/80 pt-8 text-center text-xs text-slate-500">
          <p>EV Charge Terminal Solutions Pvt. Ltd. Corporate Identification Number (CIN): U72900RJ2026PTC099881</p>
        </div>
      </div>
    </div>
  );
}
