import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Map, Zap, CreditCard, Clock, BatteryCharging, Radio, BatteryMedium, Key, Activity, ShieldCheck, ChevronRight, Cpu } from 'lucide-react';

/* ─────────────────────────────────────────────────────────
   MICRO-COMPONENTS (Bespoke Hardware Aesthetic)
   ───────────────────────────────────────────────────────── */
const MicroTag = ({ text, top, right, bottom, left, color = '#94a3b8' }) => (
  <div style={{ position: 'absolute', top, right, bottom, left, fontFamily: 'monospace', fontSize: 9, fontWeight: 800, color, letterSpacing: '0.1em', padding: '4px 8px', borderRadius: 4, zIndex: 20 }}>
    [{text}]
  </div>
);

const GrainOverlay = () => (
  <div style={{ position: 'absolute', inset: 0, opacity: 0.03, pointerEvents: 'none', mixBlendMode: 'multiply', backgroundImage: 'url("https://grainy-gradients.vercel.app/noise.svg")' }} />
);

/* ─────────────────────────────────────────────────────────
   MAIN FEATURES SECTION
   ───────────────────────────────────────────────────────── */
const FeaturesSection = () => {
  const [activeCard, setActiveCard] = useState(null);

  const cardVariants = {
    hover: { y: -8, scale: 1.01, boxShadow: '24px 24px 0 rgba(15,23,42,0.1)' }
  };

  return (
    <section id="features" className="py-16 md:py-24 lg:py-32" style={{ background: '#fff', position: 'relative', overflow: 'hidden', fontFamily: 'var(--font-body)' }}>
      <GrainOverlay />

      {/* Background Frame */}
      <div className="grid-lines" style={{ position: 'absolute', inset: 0, opacity: 0.6 }} />
      <div style={{ position: 'absolute', top: '15%', left: 0, right: 0, height: 1, background: '#e2e8f0' }} />

      <div style={{ maxWidth: 1280, margin: '0 auto', padding: '0 24px', position: 'relative', zIndex: 10 }}>

        {/* Header */}
        <div style={{ textAlign: 'center', maxWidth: 760, margin: '0 auto 60px' }}>
          <motion.div initial={{ opacity: 0, y: 10 }} whileInView={{ opacity: 1, y: 0 }} style={{ display: 'inline-flex', alignItems: 'center', gap: 10, padding: '8px 16px', borderRadius: 99, background: '#f8fafc', border: '2px solid #0f172a', color: '#0f172a', fontSize: 11, fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.1em', marginBottom: 24, boxShadow: '4px 4px 0 #D4AF37' }}>
            <Cpu size={14} color="#16a34a" /> Hardware & Platform
          </motion.div>
        </div>

        {/* Bento Grid */}
        <div className="grid grid-cols-12 gap-6 lg:gap-8">

          {/* LARGE CARD: How the Application Works */}
          <motion.div
            onHoverStart={() => setActiveCard('universal')} onHoverEnd={() => setActiveCard(null)}
            variants={cardVariants} whileHover="hover"
            initial={{ opacity: 0, y: 40 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }}
            className="col-span-12 p-6 md:p-10 lg:p-16 grid grid-cols-1 lg:grid-cols-[1.2fr_1fr] gap-8 lg:gap-16 items-center"
            style={{ background: '#fff', borderRadius: 32, border: '3px solid #0f172a', position: 'relative', overflow: 'hidden', boxShadow: '16px 16px 0 #0f172a' }}
          >
            <MicroTag text="OCPP_GATEWAY" top={24} right={24} />
            <MicroTag text="SYSTEM_HANDSHAKE" bottom={24} left={64} />

            <div>
              <div style={{ width: 64, height: 64, borderRadius: 16, background: '#0f172a', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 32 }}>
                <BatteryCharging size={32} color="#16a34a" />
              </div>
              <h3 style={{ fontFamily: 'var(--font-display)', fontSize: 'clamp(2rem, 4vw, 3rem)', fontWeight: 800, color: '#0f172a', margin: '0 0 20px 0', lineHeight: 1.1 }}>Working of the Application</h3>
              <p style={{ fontSize: '1.1rem', color: '#64748b', fontWeight: 500, lineHeight: 1.6, margin: '0 0 32px' }}>
                EV Charge connects your vehicle to a unified real-time charging network. Browse stations, book slots, and stream live charging telemetry straight to your dashboard.
              </p>

              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12 }}>
                {['1. FIND STATION', '2. BOOK SESSION', '3. CHARGE & STREAM'].map((tag, i) => (
                  <div key={i} style={{ padding: '8px 14px', borderRadius: 10, background: '#f1f5f9', border: '1px solid #e2e8f0', fontSize: 11, fontWeight: 900, color: '#0f172a', fontFamily: 'monospace' }}>{tag}</div>
                ))}
              </div>
            </div>

            <div className="h-[300px] md:h-[400px]" style={{ position: 'relative', width: '100%', background: '#f8fafc', borderRadius: 24, border: '2px solid #0f172a', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <div className="grid-lines" style={{ position: 'absolute', inset: 0, opacity: 0.5 }} />
              <motion.div animate={{ rotate: 360 }} transition={{ duration: 30, repeat: Infinity, ease: 'linear' }} style={{ position: 'absolute', width: 500, height: 500, border: '1px dashed #cbd5e1', borderRadius: '50%' }} />

              {/* Technical Blueprint SVG showing connection flow */}
              <svg width="280" height="280" viewBox="0 0 280 280" style={{ position: 'relative', zIndex: 10 }}>
                {/* Connection dotted lines */}
                <motion.path
                  d="M 50,70 L 140,190"
                  stroke="#64748b"
                  strokeWidth="2"
                  strokeDasharray="4 4"
                  animate={{ strokeDashoffset: [0, -20] }}
                  transition={{ duration: 5, repeat: Infinity, ease: 'linear' }}
                />
                <motion.path
                  d="M 230,70 L 140,190"
                  stroke="#64748b"
                  strokeWidth="2"
                  strokeDasharray="4 4"
                  animate={{ strokeDashoffset: [0, -20] }}
                  transition={{ duration: 5, repeat: Infinity, ease: 'linear' }}
                />
                <motion.path
                  d="M 50,70 L 230,70"
                  stroke="#64748b"
                  strokeWidth="2"
                  strokeDasharray="4 4"
                  animate={{ strokeDashoffset: [0, 20] }}
                  transition={{ duration: 5, repeat: Infinity, ease: 'linear' }}
                />

                {/* Web Client Node */}
                <g transform="translate(50,70)">
                  <circle r="24" fill="#fff" stroke="#0f172a" strokeWidth="3" />
                  <Map size={18} color="#0f172a" style={{ transform: 'translate(-9px, -9px)' }} />
                  <text x="0" y="38" textAnchor="middle" fontFamily="monospace" fontSize="8" fontWeight="bold" fill="#0f172a">1. FIND</text>
                </g>

                {/* Server Gateway Node */}
                <g transform="translate(230,70)">
                  <circle r="24" fill="#fff" stroke="#0f172a" strokeWidth="3" />
                  <Cpu size={18} color="#0f172a" style={{ transform: 'translate(-9px, -9px)' }} />
                  <text x="0" y="38" textAnchor="middle" fontFamily="monospace" fontSize="8" fontWeight="bold" fill="#0f172a">2. BOOK</text>
                </g>

                {/* Charger Node */}
                <g transform="translate(140,190)">
                  <circle r="28" fill="#fff" stroke="#16a34a" strokeWidth="3" />
                  <BatteryCharging size={22} color="#16a34a" style={{ transform: 'translate(-11px, -11px)' }} />
                  <text x="0" y="42" textAnchor="middle" fontFamily="monospace" fontSize="8" fontWeight="bold" fill="#16a34a">3. STREAM</text>
                </g>
              </svg>

              <div style={{ position: 'absolute', bottom: 24, right: 24, background: '#D4AF37', color: '#fff', padding: '6px 12px', borderRadius: 8, fontSize: 11, fontWeight: 900, fontFamily: 'monospace' }}>ACTIVE_SYNC</div>
            </div>
          </motion.div>

          {/* MEDIUM CARD: Real-time Telemetry */}
          <motion.div
            variants={cardVariants} whileHover="hover"
            initial={{ opacity: 0, y: 40 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: 0.1 }}
            className="col-span-12 lg:col-span-7 p-6 md:p-10 lg:p-12"
            style={{ background: '#0f172a', borderRadius: 32, color: '#fff', position: 'relative', overflow: 'hidden', boxShadow: '16px 16px 0 rgba(15,23,42,0.1)' }}
          >
            <MicroTag text="DATA_LINK_v3" top={24} right={24} color="rgba(255,255,255,0.4)" />
            <div className="animate-scan" style={{ position: 'absolute', left: 0, right: 0, height: 120, background: 'linear-gradient(transparent, rgba(22,163,74,0.08), transparent)', pointerEvents: 'none' }} />

            <div style={{ width: 56, height: 56, borderRadius: 16, border: '2px solid rgba(255,255,255,0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 32 }}>
              <Radio size={28} color="#16a34a" />
            </div>

            <h3 style={{ fontFamily: 'var(--font-display)', fontSize: 'clamp(2rem, 3.5vw, 2.5rem)', fontWeight: 800, margin: '0 0 16px 0', lineHeight: 1.1 }}>Live Ingestion</h3>
            <p style={{ fontSize: '1.05rem', color: 'rgba(255,255,255,0.6)', fontWeight: 500, lineHeight: 1.6, maxWidth: 380, margin: '0 0 40px 0' }}>
              We track charger health from 150+ networks in 5-second intervals. Guaranteed 99.9% terminal uptime.
            </p>

            <div style={{ background: 'rgba(255,255,255,0.03)', border: '2px solid rgba(255,255,255,0.1)', borderRadius: 20, padding: 24 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <div style={{ width: 8, height: 8, background: '#16a34a', borderRadius: '50%', boxShadow: '0 0 10px rgba(22,163,74,0.4)' }} />
                  <span style={{ fontSize: 10, fontWeight: 900, letterSpacing: '0.1em' }}>STREAM_ACTIVE</span>
                </div>
                <span style={{ fontSize: 10, fontWeight: 800, color: '#D4AF37' }}>426ms_LATENCY</span>
              </div>
              <div style={{ height: 60, display: 'flex', alignItems: 'end', gap: 4 }}>
                {[30, 60, 40, 90, 50, 70, 40, 80, 100, 60, 40, 85].map((h, i) => (
                  <motion.div key={i} animate={{ height: [`${h}%`, `${Math.max(20, Math.random() * 100)}%`, `${h}%`] }} transition={{ duration: 3, repeat: Infinity, delay: i * 0.1 }} style={{ flex: 1, background: '#16a34a', borderRadius: 2 }} />
                ))}
              </div>
            </div>
          </motion.div>

          {/* MEDIUM CARD: Dynamic Pricing */}
          <motion.div
            variants={cardVariants} whileHover="hover"
            initial={{ opacity: 0, y: 40 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: 0.2 }}
            className="col-span-12 lg:col-span-5 p-6 md:p-10 lg:p-12"
            style={{ background: 'linear-gradient(135deg, #0f172a 0%, #1e293b 100%)', borderRadius: 32, border: '3px solid #16a34a', position: 'relative', overflow: 'hidden', boxShadow: '16px 16px 0 #0f172a' }}
          >
            <MicroTag text="LEDGER_STRICT" top={24} right={24} color="#D4AF37" />

            <div style={{ width: 56, height: 56, borderRadius: 16, background: '#0f172a', border: '2px solid #D4AF37', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 32 }}>
              <CreditCard size={28} color="#D4AF37" />
            </div>

            <h3 style={{ fontFamily: 'var(--font-display)', fontSize: 'clamp(2rem, 3.5vw, 2.5rem)', fontWeight: 800, color: '#fff', margin: '0 0 16px 0', lineHeight: 1.1 }}>Transparent</h3>
            <p style={{ fontSize: '1.05rem', color: '#94a3b8', fontWeight: 600, lineHeight: 1.5, margin: '0 0 40px 0' }}>
              Real-time rate forecasting. See exactly what you pay before the cable is plugged.
            </p>

            <div style={{ background: 'rgba(255, 255, 255, 0.03)', border: '2px solid #D4AF37', borderRadius: 20, padding: 24, boxShadow: '6px 6px 0 rgba(0,0,0,0.2)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                <span style={{ fontSize: 11, fontWeight: 800, color: '#64748b' }}>EST. RATE</span>
                <span style={{ fontSize: 11, fontWeight: 900, color: '#D4AF37' }}>+0.2% AVG</span>
              </div>
              <p style={{ fontFamily: 'var(--font-display)', fontSize: 36, fontWeight: 900, color: '#fff', margin: 0 }}>$0.34<span style={{ fontSize: 14, color: '#64748b' }}>/kWh</span></p>
            </div>
          </motion.div>

        </div>
      </div>
    </section>
  );
};

export default FeaturesSection;
