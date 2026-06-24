import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import { Zap, Globe, Cpu, Activity, Clock, Terminal, ShieldCheck, BarChart3, Radio } from 'lucide-react';

/* ─────────────────────────────────────────────────────────
   MICRO-COMPONENTS (System Dashboard Style)
   ───────────────────────────────────────────────────────── */
const SystemMetric = ({ label, value, color = '#16a34a' }) => (
  <div style={{ padding: '12px 24px', borderRight: '1px solid #e2e8f0', display: 'flex', flexDirection: 'column', gap: 4 }}>
    <span style={{ fontSize: 9, fontWeight: 900, color: '#94a3b8', letterSpacing: '0.12em', textTransform: 'uppercase' }}>{label}</span>
    <span style={{ fontSize: 13, fontWeight: 800, color, fontFamily: 'monospace' }}>[{value}]</span>
  </div>
);

const DigitalClock = () => {
  const [time, setTime] = useState(new Date().toLocaleTimeString());
  useEffect(() => {
    const interval = setInterval(() => setTime(new Date().toLocaleTimeString()), 1000);
    return () => clearInterval(interval);
  }, []);
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px 24px', borderLeft: '1px solid #e2e8f0' }}>
      <Clock size={14} color="#16a34a" />
      <span style={{ fontSize: 13, fontWeight: 900, color: '#0f172a', fontFamily: 'monospace' }}>{time}</span>
    </div>
  );
};

/* ─────────────────────────────────────────────────────────
   MAIN SYSTEM FOOTER
   ───────────────────────────────────────────────────────── */
const Footer = () => {
  const [latency, setLatency] = useState(24);
  useEffect(() => {
    const interval = setInterval(() => {
      setLatency(prev => Math.max(18, Math.min(32, prev + (Math.random() > 0.5 ? 1 : -1))));
    }, 2000);
    return () => clearInterval(interval);
  }, []);

  const legalColumns = [
    [
      { label: 'About Us', path: '/about' },
      { label: 'Contact Us', path: '/contact' }
    ],
    [
      { label: 'Terms & Conditions', path: '/terms' },
      { label: 'Privacy Policy', path: '/privacy' }
    ],
    [
      { label: 'Refund Policy', path: '/refunds' }
    ]
  ];

  return (
    <footer style={{ background: '#fff', fontFamily: 'var(--font-body)', position: 'relative', overflow: 'hidden', borderTop: '1px solid #e2e8f0' }}>

      {/* Architectural Frame Base */}
      <div className="grid-lines" style={{ position: 'absolute', inset: 0, opacity: 0.3, pointerEvents: 'none' }} />
      <div className="hidden lg:block" style={{ position: 'absolute', top: 0, bottom: 0, left: '8%', width: 1, background: '#f1f5f9', pointerEvents: 'none' }} />
      <div className="hidden lg:block" style={{ position: 'absolute', top: 0, bottom: 0, left: '92%', width: 1, background: '#f1f5f9', pointerEvents: 'none' }} />

      <div style={{ maxWidth: 1440, margin: '0 auto', padding: '0 24px', position: 'relative', zIndex: 10 }}>

        {/* TOP STATUS BAR (Network Dashboard) */}
        <div style={{ borderBottom: '1px solid #e2e8f0', background: '#f8fafc' }} className="hidden md:flex">
          <SystemMetric label="Server Hub" value="US-EAST-GLOBAL" />
          <SystemMetric label="API Latency" value={`${latency}ms`} color={latency > 28 ? '#ef4444' : '#16a34a'} />
          <SystemMetric label="Uptime" value="99.998%" />
          <SystemMetric label="Current Version" value="v1.0.42_STABLE" />
          <div style={{ flex: 1 }} />
          <DigitalClock />
        </div>

        {/* MAIN NAV SECTION */}
        <div style={{ padding: '40px 0', gap: 32 }} className="flex flex-col lg:flex-row lg:justify-between lg:items-center flex-wrap">

          {/* Brand & Info Block */}
          <div className="flex flex-col sm:flex-row sm:items-center gap-6 flex-wrap">
            <a href="/" style={{ display: 'inline-flex', alignItems: 'center', gap: 10, textDecoration: 'none' }}>
              <div style={{ width: 36, height: 36, borderRadius: 8, background: '#16a34a', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Zap size={18} color="#fff" fill="#fff" />
              </div>
              <span style={{ fontFamily: 'var(--font-display)', fontSize: 22, fontWeight: 900, color: '#0f172a', letterSpacing: '-0.04em' }}>EV Charge</span>
            </a>
            <div style={{ width: 1, height: 24, background: '#e2e8f0' }} className="hidden sm:block" />
            <p style={{ fontSize: '0.9rem', color: '#64748b', fontWeight: 600, margin: 0, maxWidth: 360 }}>
              High-performance EV charging infrastructure terminal. Real-time telemetry, smart routing, and global connectivity.
            </p>
          </div>

          {/* Legal & Compliance horizontal block containing vertical column pairs */}
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 12 }}>
            <span style={{ fontSize: 9, fontWeight: 900, color: '#383a3bff', letterSpacing: '0.12em', textTransform: 'uppercase' }}>
              Legal & Compliance
            </span>
            <div style={{ display: 'flex', gap: 40, flexWrap: 'wrap' }}>
              {legalColumns.map((col, i) => (
                <div key={i} style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                  {col.map((link, j) => {
                    const isExternalOrHash = link.path.startsWith('#') || link.path.startsWith('http');
                    return isExternalOrHash ? (
                      <motion.a
                        key={j} href={link.path}
                        whileHover={{ y: -2, color: '#16a34a' }}
                        style={{ textDecoration: 'none', color: '#64748b', fontSize: 13, fontWeight: 700, transition: 'color 0.2s' }}
                      >
                        {link.label}
                      </motion.a>
                    ) : (
                      <motion.div key={j} whileHover={{ y: -2 }}>
                        <Link
                          to={link.path}
                          style={{ textDecoration: 'none', color: '#64748b', fontSize: 13, fontWeight: 700, transition: 'color 0.2s' }}
                          className="hover:text-emerald-500"
                        >
                          {link.label}
                        </Link>
                      </motion.div>
                    );
                  })}
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* BOTTOM TERMINAL FOOTNOTE */}
        <div style={{ borderTop: '1px solid #e2e8f0', padding: '32px 0' }} className="flex flex-col md:flex-row justify-between items-center gap-6 md:gap-0">
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }} className="flex-col md:flex-row text-center md:text-left">
            <div className="flex items-center gap-2">
              <Terminal size={16} color="#16a34a" />
              <span className="md:hidden" style={{ fontSize: 12, fontWeight: 700, color: '#94a3b8' }}>EV Charge</span>
            </div>
            <p style={{ fontSize: 12, fontWeight: 700, color: '#94a3b8', margin: 0 }}>
              &copy; {new Date().getFullYear()} EV Charge Powered by S.AIntelligence Technologies
            </p>
          </div>

          {/* Architectural Social Boxes */}
          <div style={{ display: 'flex', gap: 8 }} className="flex-wrap justify-center">
            {['X_SYS', 'IG_HLD', 'LI_CORP', 'GH_DEV'].map((tag, i) => (
              <motion.a
                key={i} href="#"
                whileHover={{ y: -4, borderColor: '#16a34a', color: '#16a34a', boxShadow: '4px 4px 0 #16a34a' }}
                style={{ padding: '8px 12px', border: '2px solid #e2e8f0', borderRadius: 8, background: '#fff', textDecoration: 'none', fontSize: 10, fontWeight: 900, color: '#94a3b8', fontFamily: 'monospace', transition: 'all 0.2s' }}
              >
                {tag}
              </motion.a>
            ))}
          </div>
        </div>

      </div>
    </footer>
  );
};

export default Footer;