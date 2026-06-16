import React, { useState, useEffect, useCallback, useRef } from 'react';
import { motion, animate, AnimatePresence } from 'framer-motion';
import { collection, getDocs } from 'firebase/firestore';
import { db } from '../../lib/firebase';
import useAdminSocket from './useAdminSocket';
import {
  Users, BatteryCharging, IndianRupee, Activity, ShieldAlert,
  Radio, Cpu, Zap, Search, TrendingUp, MapPin, Clock,
  CheckCircle2, XCircle, AlertCircle, LayoutGrid, List,
  RefreshCw, Globe, Terminal, Plus, Trash2, Edit3,
  Play, Square, Wifi, WifiOff, Server, Eye, EyeOff,
  ChevronRight, Settings, ScrollText
} from 'lucide-react';

const BACKEND_URL = (import.meta.env.VITE_OCPP_REMOTE_START_BASE_URL || '').replace(/\/+$/, '');

/* ═══════════════════════════════════════════════════════════
   STYLES
   Neo-brutalist theme featuring green and gold accents.
═══════════════════════════════════════════════════════════ */
const CSS = `
  @import url('https://fonts.googleapis.com/css2?family=Space+Mono:wght@400;700&family=Inter:wght@400;500;600;700;800;900&display=swap');

  :root {
    --display: 'Inter', system-ui, sans-serif;
    --mono:    'Space Mono', monospace;
    --dark:    #0f172a;
    --green:   #16a34a;
    --gold:    #D4AF37;
    --mid:     #334155;
    --muted:   #64748b;
    --subtle:  #94a3b8;
    --border:  #e2e8f0;
    --bg:      #fff;
    --surface: #f8fafc;
    --surface2:#f1f5f9;
  }

  .admin-grid-lines {
    background-image:
      linear-gradient(rgba(15,23,42,0.04) 1px, transparent 1px),
      linear-gradient(90deg, rgba(15,23,42,0.04) 1px, transparent 1px);
    background-size: 40px 40px;
  }

  .admin-neo-card {
    background: #fff;
    border: 1px solid var(--border);
    box-shadow: 0 4px 6px -1px rgba(0,0,0,0.03), 0 2px 4px -2px rgba(0,0,0,0.03);
    transition: box-shadow 0.22s ease, transform 0.22s ease, border-color 0.22s ease;
    border-radius: 20px;
  }
  .admin-neo-card:hover {
    box-shadow: 0 10px 15px -3px rgba(0,0,0,0.05), 0 4px 6px -4px rgba(0,0,0,0.05);
    transform: translateY(-2px);
    border-color: var(--subtle);
  }

  .stat-accent-green  { border-color: var(--green); }
  .stat-accent-gold   { border-color: var(--green); }
  .stat-accent-green:hover  { box-shadow: 0 10px 15px -3px rgba(22,163,74,0.08) !important; }
  .stat-accent-gold:hover   { box-shadow: 0 10px 15px -3px rgba(22,163,74,0.08) !important; }

  @keyframes admin-scan-wipe {
    0%   { left: -10%; opacity: 0; }
    5%   { opacity: 1; }
    95%  { opacity: 1; }
    100% { left: 110%; opacity: 0; }
  }
  .admin-scan-wipe { animation: admin-scan-wipe 9s linear infinite; }

  @keyframes admin-marquee {
    0%   { transform: translateX(0); }
    100% { transform: translateX(-50%); }
  }

  @keyframes admin-pulse-ring {
    0%   { box-shadow: 0 0 0 0   rgba(212,175,55,0.55); }
    100% { box-shadow: 0 0 0 10px rgba(212,175,55,0); }
  }
  .admin-pulse-dot { animation: admin-pulse-ring 2s ease-out infinite; }

  @keyframes admin-shimmer {
    0%   { background-position: -600px 0; }
    100% { background-position:  600px 0; }
  }
  .admin-shimmer {
    background: linear-gradient(90deg, #f1f5f9 0px, #e2e8f0 300px, #f1f5f9 600px);
    background-size: 1200px 100%;
    animation: admin-shimmer 1.5s ease-in-out infinite;
  }

  @keyframes admin-spin { to { transform: rotate(360deg); } }

  .admin-tab-btn {
    padding: 10px 22px;
    border-radius: 10px;
    border: 1.5px solid var(--border);
    cursor: pointer;
    font-family: var(--display);
    font-size: 13px;
    font-weight: 600;
    transition: all 0.2s ease;
    background: #fff;
    color: var(--muted);
    display: flex; align-items: center; gap: 8px;
  }
  .admin-tab-btn:hover { background: var(--surface); color: var(--dark); border-color: var(--subtle); }
  .admin-tab-btn.active {
    background: var(--dark);
    color: #fff;
    border-color: var(--dark);
  }

  .admin-input {
    background: #fff;
    border: 1.5px solid var(--border);
    border-radius: 10px;
    padding: 10px 14px;
    font-family: var(--display);
    font-size: 14px;
    font-weight: 600;
    color: var(--dark);
    outline: none;
    width: 100%;
    transition: border-color 0.18s, box-shadow 0.18s;
  }
  .admin-input:focus {
    border-color: var(--green);
    box-shadow: 0 0 0 3px rgba(22,163,74,0.1);
  }
  .admin-input::placeholder { color: var(--subtle); font-weight: 500; }

  .admin-btn {
    padding: 10px 20px;
    border-radius: 10px;
    border: 1.5px solid var(--border);
    font-family: var(--display);
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    display: inline-flex; align-items: center; gap: 8px;
    transition: all 0.18s ease;
  }
  .admin-btn:hover { transform: translateY(-1px); border-color: var(--subtle); }
  .admin-btn-primary { background: var(--green); color: #fff; border-color: var(--green); }
  .admin-btn-primary:hover { background: #15803d; border-color: #15803d; }
  .admin-btn-danger { background: #dc2626; color: #fff; border-color: #dc2626; }
  .admin-btn-danger:hover { background: #b91c1c; border-color: #b91c1c; }
  .admin-btn-ghost { background: transparent; color: var(--dark); border-color: var(--border); }

  .admin-search-wrap {
    display: flex; align-items: center; gap: 10px;
    background: #fff; border: 1.5px solid var(--border);
    border-radius: 12px; padding: 10px 16px;
    transition: border-color 0.18s, box-shadow 0.18s;
  }
  .admin-search-wrap:focus-within {
    border-color: var(--green);
    box-shadow: 0 0 0 3px rgba(22,163,74,0.1);
  }
  .admin-search-wrap input {
    background: transparent; border: none; outline: none;
    font-family: var(--display); font-size: 14px; font-weight: 600;
    color: var(--dark); width: 100%;
  }
  .admin-search-wrap input::placeholder { color: var(--subtle); font-weight: 500; }

  .admin-trow { transition: background 0.15s; }
  .admin-trow:hover { background: var(--surface); }

  .admin-station-card {
    background: #fff; border: 1px solid var(--border);
    border-radius: 18px; padding: 22px;
    box-shadow: 0 4px 6px -1px rgba(0,0,0,0.02);
    transition: box-shadow 0.2s ease, transform 0.2s ease, border-color 0.2s ease;
    position: relative; overflow: hidden;
  }
  .admin-station-card:hover {
    box-shadow: 0 10px 15px -3px rgba(0,0,0,0.05);
    transform: translateY(-2px);
    border-color: var(--subtle);
  }

  .admin-log-entry {
    padding: 8px 14px;
    border-bottom: 1px solid #f1f5f9;
    font-family: var(--mono);
    font-size: 11px;
    display: flex; gap: 10px; align-items: flex-start;
  }
  .admin-log-entry:hover { background: #f8fafc; }

  .admin-badge {
    font-family: var(--mono);
    font-size: 9px; font-weight: 700;
    letter-spacing: 0.1em; text-transform: uppercase;
    padding: 3px 9px; border-radius: 4px;
    border: 1.5px solid currentColor;
    display: inline-flex; align-items: center; gap: 4px;
    white-space: nowrap;
  }

  .admin-modal-overlay {
    position: fixed; inset: 0; z-index: 1000;
    background: rgba(15,23,42,0.6);
    backdrop-filter: blur(8px);
    display: flex; align-items: center; justify-content: center;
    padding: 24px;
  }
  .admin-modal {
    background: #fff; border: 1px solid var(--border);
    border-radius: 24px; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1), 0 10px 10px -5px rgba(0,0,0,0.04);
    max-width: 560px; width: 100%; max-height: 90vh;
    overflow-y: auto; padding: 32px;
  }

  @media (max-width: 900px) {
    .admin-stat-grid { grid-template-columns: 1fr 1fr !important; }
    .admin-hero-right { display: none !important; }
  }
  @media (max-width: 520px) {
    .admin-stat-grid { grid-template-columns: 1fr !important; }
    .admin-hide-sm { display: none !important; }
  }
`;

/* ── Animated counter ── */
const Counter = ({ to, prefix = '', suffix = '', decimals = 0, duration = 2 }) => {
  const ref = useRef(null);
  const [vis, setVis] = useState(false);
  useEffect(() => {
    const obs = new IntersectionObserver(([e]) => { if (e.isIntersecting) setVis(true); }, { threshold: 0.3 });
    if (ref.current) obs.observe(ref.current);
    return () => obs.disconnect();
  }, []);
  useEffect(() => {
    if (!vis || !ref.current) return;
    const ctrl = animate(0, to, {
      duration, ease: 'easeOut',
      onUpdate: v => { if (ref.current) ref.current.textContent = prefix + (decimals ? v.toFixed(decimals) : Math.round(v).toLocaleString('en-IN')) + suffix; }
    });
    return () => ctrl.stop();
  }, [vis, to]);
  return <span ref={ref}>{prefix}0{suffix}</span>;
};

/* ── Ticker ── */
const Ticker = ({ items }) => (
  <div style={{ overflow: 'hidden', borderTop: '1px solid #1e293b', borderBottom: '1px solid #1e293b', background: '#0f172a', padding: '10px 0' }}>
    <div style={{ display: 'flex', animation: 'admin-marquee 26s linear infinite', width: 'max-content' }}>
      {[...items, ...items].map((t, i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '0 44px', whiteSpace: 'nowrap' }}>
          <Zap size={11} color="#16a34a" fill="#16a34a" />
          <span style={{ fontFamily: 'var(--mono)', fontSize: 10, fontWeight: 700, color: '#94a3b8', letterSpacing: '0.12em' }}>{t}</span>
        </div>
      ))}
    </div>
  </div>
);

/* ── Status badge ── */
const StatusBadge = ({ status = 'Unavailable' }) => {
  const s = (status || '').toLowerCase();
  const map = {
    available:  { color: '#16a34a', bg: '#f0fdf4', label: 'Available' },
    charging:   { color: '#2563eb', bg: '#eff6ff', label: 'Charging' },
    preparing:  { color: '#d97706', bg: '#fffbeb', label: 'Preparing' },
    faulted:    { color: '#dc2626', bg: '#fef2f2', label: 'Faulted' },
    unavailable:{ color: '#64748b', bg: '#f1f5f9', label: 'Unavailable' },
    finishing:  { color: '#7c3aed', bg: '#ede9fe', label: 'Finishing' },
  };
  const m = map[s] || map.unavailable;
  return <span className="admin-badge" style={{ color: m.color, background: m.bg, borderColor: m.color }}>{m.label}</span>;
};

/* ── Online badge ── */
const OnlineBadge = ({ online }) => (
  <span className="admin-badge" style={{
    color: online ? '#16a34a' : '#94a3b8',
    background: online ? '#f0fdf4' : '#f8fafc',
    borderColor: online ? '#16a34a' : '#e2e8f0',
  }}>
    {online ? <><Wifi size={9} /> Online</> : <><WifiOff size={9} /> Offline</>}
  </span>
);

/* ═══════════════════════════════════════════════════════════
   ADD STATION MODAL
═══════════════════════════════════════════════════════════ */
const AddStationModal = ({ onClose, onSave, editing }) => {
  const [form, setForm] = useState({
    stationId: editing?.id || editing?.ocppStationId || '',
    name: editing?.name || '',
    lat: editing?.lat || '',
    lng: editing?.lng || '',
    chargerType: editing?.chargerType || 'Type 2 AC',
    connectorId: editing?.connectorId || 1,
    pricePerHour: editing?.pricePerHour || 15,
    energyRatePerKwh: editing?.energyRatePerKwh || 12,
    availableSlots: editing?.availableSlots || 1,
    published: editing?.published !== false,
  });
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    if (!form.stationId.trim()) return;
    setSaving(true);
    try {
      await onSave(form);
      onClose();
    } catch (e) {
      console.error(e);
    }
    setSaving(false);
  };

  const fieldStyle = { marginBottom: 16 };
  const labelStyle = { fontFamily: 'var(--mono)', fontSize: 10, fontWeight: 700, color: '#94a3b8', letterSpacing: '0.1em', marginBottom: 6, display: 'block', textTransform: 'uppercase' };

  return (
    <div className="admin-modal-overlay" onClick={onClose}>
      <motion.div className="admin-modal" onClick={e => e.stopPropagation()}
        initial={{ opacity: 0, y: 20, scale: 0.96 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: 20, scale: 0.96 }}
      >
        <h2 style={{ fontFamily: 'var(--display)', fontWeight: 900, fontSize: '1.5rem', color: '#0f172a', marginBottom: 24 }}>
          {editing ? 'Edit Station' : 'Add New Station'}
        </h2>

        <div style={fieldStyle}>
          <label style={labelStyle}>Station ID (OCPP Identity)</label>
          <input className="admin-input" value={form.stationId} onChange={e => setForm({ ...form, stationId: e.target.value })}
            placeholder="e.g. CHARGER-001" disabled={!!editing} />
        </div>

        <div style={fieldStyle}>
          <label style={labelStyle}>Station Name</label>
          <input className="admin-input" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })}
            placeholder="e.g. Main Street Charger" />
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14, ...fieldStyle }}>
          <div>
            <label style={labelStyle}>Latitude</label>
            <input className="admin-input" type="number" step="any" value={form.lat} onChange={e => setForm({ ...form, lat: e.target.value })} placeholder="26.1443" />
          </div>
          <div>
            <label style={labelStyle}>Longitude</label>
            <input className="admin-input" type="number" step="any" value={form.lng} onChange={e => setForm({ ...form, lng: e.target.value })} placeholder="91.7363" />
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14, ...fieldStyle }}>
          <div>
            <label style={labelStyle}>Charger Type</label>
            <select className="admin-input" value={form.chargerType} onChange={e => setForm({ ...form, chargerType: e.target.value })}>
              <option>Type 2 AC</option>
              <option>CCS DC</option>
              <option>CHAdeMO</option>
              <option>Type 1 AC</option>
            </select>
          </div>
          <div>
            <label style={labelStyle}>Connector ID</label>
            <input className="admin-input" type="number" value={form.connectorId} onChange={e => setForm({ ...form, connectorId: parseInt(e.target.value) || 1 })} />
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 14, ...fieldStyle }}>
          <div>
            <label style={labelStyle}>₹/Hour</label>
            <input className="admin-input" type="number" value={form.pricePerHour} onChange={e => setForm({ ...form, pricePerHour: parseFloat(e.target.value) || 0 })} />
          </div>
          <div>
            <label style={labelStyle}>₹/kWh</label>
            <input className="admin-input" type="number" value={form.energyRatePerKwh} onChange={e => setForm({ ...form, energyRatePerKwh: parseFloat(e.target.value) || 0 })} />
          </div>
          <div>
            <label style={labelStyle}>Slots</label>
            <input className="admin-input" type="number" value={form.availableSlots} onChange={e => setForm({ ...form, availableSlots: parseInt(e.target.value) || 1 })} />
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 24 }}>
          <input type="checkbox" checked={form.published} onChange={e => setForm({ ...form, published: e.target.checked })}
            style={{ width: 18, height: 18, accentColor: '#16a34a' }} />
          <span style={{ fontFamily: 'var(--display)', fontSize: 14, fontWeight: 700, color: '#0f172a' }}>Publish to users</span>
        </div>

        <div style={{ display: 'flex', gap: 12, justifyContent: 'flex-end' }}>
          <button className="admin-btn admin-btn-ghost" onClick={onClose}>Cancel</button>
          <button className="admin-btn admin-btn-primary" onClick={handleSave} disabled={saving}>
            {saving ? <RefreshCw size={13} style={{ animation: 'admin-spin 0.8s linear infinite' }} /> : <Plus size={13} />}
            {editing ? 'Update' : 'Add Station'}
          </button>
        </div>
      </motion.div>
    </div>
  );
};

/* ═══════════════════════════════════════════════════════════
   COMMAND CENTER (START / STOP CHARGING TEST)
═══════════════════════════════════════════════════════════ */
const CommandCenter = ({ stations, liveChargers }) => {
  const [selectedStation, setSelectedStation] = useState('');
  const [connectorId, setConnectorId] = useState(1);
  const [idTag, setIdTag] = useState('ADMIN_TEST');
  const [cmdLog, setCmdLog] = useState([]);
  const [loading, setLoading] = useState(null);

  const addCmdLog = (entry) => {
    setCmdLog(prev => [{ ...entry, id: Date.now(), at: new Date().toLocaleTimeString() }, ...prev].slice(0, 50));
  };

  const sendCommand = async (action) => {
    if (!selectedStation) return;
    setLoading(action);
    addCmdLog({ type: 'sent', action, stationId: selectedStation, message: `Sending ${action}...` });

    try {
      const endpoint = action === 'RemoteStartTransaction' ? '/remote-start' : '/remote-stop';
      const body = action === 'RemoteStartTransaction'
        ? { stationId: selectedStation, connectorId, idTag }
        : { stationId: selectedStation };

      const res = await fetch(`${BACKEND_URL}${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      const data = await res.json();

      if (res.ok) {
        addCmdLog({ type: 'success', action, stationId: selectedStation, message: `${action} → ${JSON.stringify(data)}` });
      } else {
        addCmdLog({ type: 'error', action, stationId: selectedStation, message: `Error: ${data.error || res.statusText}` });
      }
    } catch (err) {
      addCmdLog({ type: 'error', action, stationId: selectedStation, message: `Network error: ${err.message}` });
    }
    setLoading(null);
  };

  const allStationIds = [...new Set([
    ...stations.map(s => s.ocppStationId || s.id),
    ...liveChargers.map(c => c.id),
  ])];

  const isOnline = liveChargers.find(c => c.id === selectedStation)?.connected;

  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginBottom: 24 }}>
        <div style={{ background: '#fff', border: '2px solid #0f172a', borderRadius: 18, padding: 24, boxShadow: '6px 6px 0 #0f172a' }}>
          <h3 style={{ fontFamily: 'var(--display)', fontWeight: 800, fontSize: '1.1rem', color: '#0f172a', marginBottom: 20 }}>
            <Terminal size={18} style={{ verticalAlign: 'middle', marginRight: 8 }} />
            Command Terminal
          </h3>

          <div style={{ marginBottom: 16 }}>
            <label style={{ fontFamily: 'var(--mono)', fontSize: 10, fontWeight: 700, color: '#94a3b8', letterSpacing: '0.1em', display: 'block', marginBottom: 6 }}>
              TARGET STATION
            </label>
            <select className="admin-input" value={selectedStation} onChange={e => setSelectedStation(e.target.value)}>
              <option value="">— Select Station —</option>
              {allStationIds.map(id => (
                <option key={id} value={id}>{id} {liveChargers.find(c => c.id === id)?.connected ? '🟢' : '⚫'}</option>
              ))}
            </select>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 16 }}>
            <div>
              <label style={{ fontFamily: 'var(--mono)', fontSize: 10, fontWeight: 700, color: '#94a3b8', letterSpacing: '0.1em', display: 'block', marginBottom: 6 }}>CONNECTOR ID</label>
              <input className="admin-input" type="number" value={connectorId} onChange={e => setConnectorId(parseInt(e.target.value) || 1)} />
            </div>
            <div>
              <label style={{ fontFamily: 'var(--mono)', fontSize: 10, fontWeight: 700, color: '#94a3b8', letterSpacing: '0.1em', display: 'block', marginBottom: 6 }}>ID TAG</label>
              <input className="admin-input" value={idTag} onChange={e => setIdTag(e.target.value)} />
            </div>
          </div>

          {selectedStation && (
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16, padding: '8px 12px', background: isOnline ? '#f0fdf4' : '#fef2f2', borderRadius: 10, border: `1.5px solid ${isOnline ? '#16a34a' : '#dc2626'}30` }}>
              {isOnline ? <Wifi size={12} color="#16a34a" /> : <WifiOff size={12} color="#dc2626" />}
              <span style={{ fontFamily: 'var(--mono)', fontSize: 10, fontWeight: 700, color: isOnline ? '#16a34a' : '#dc2626', letterSpacing: '0.08em' }}>
                {isOnline ? 'CHARGER ONLINE' : 'CHARGER OFFLINE — COMMAND MAY FAIL'}
              </span>
            </div>
          )}

          <div style={{ display: 'flex', gap: 12 }}>
            <button className="admin-btn admin-btn-primary" onClick={() => sendCommand('RemoteStartTransaction')}
              disabled={!selectedStation || loading}>
              {loading === 'RemoteStartTransaction'
                ? <RefreshCw size={13} style={{ animation: 'admin-spin 0.8s linear infinite' }} />
                : <Play size={13} />}
              Start Charging
            </button>
            <button className="admin-btn admin-btn-danger" onClick={() => sendCommand('RemoteStopTransaction')}
              disabled={!selectedStation || loading}>
              {loading === 'RemoteStopTransaction'
                ? <RefreshCw size={13} style={{ animation: 'admin-spin 0.8s linear infinite' }} />
                : <Square size={13} />}
              Stop Charging
            </button>
          </div>
        </div>

        {/* Command Log */}
        <div style={{ background: '#0f172a', border: '2px solid #0f172a', borderRadius: 18, padding: 0, boxShadow: '6px 6px 0 var(--gold)', overflow: 'hidden', display: 'flex', flexDirection: 'column', maxHeight: 440 }}>
          <div style={{ padding: '14px 20px', borderBottom: '1px solid #1e293b', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontFamily: 'var(--mono)', fontSize: 11, fontWeight: 700, color: '#fbbf24', letterSpacing: '0.1em' }}>
              <Terminal size={12} style={{ verticalAlign: 'middle', marginRight: 6 }} />
              COMMAND LOG
            </span>
            <button onClick={() => setCmdLog([])} style={{ background: 'none', border: 'none', color: '#475569', cursor: 'pointer', fontFamily: 'var(--mono)', fontSize: 9, fontWeight: 700 }}>CLEAR</button>
          </div>
          <div style={{ flex: 1, overflowY: 'auto', padding: '8px 0' }}>
            {cmdLog.length === 0 ? (
              <div style={{ padding: 40, textAlign: 'center', color: '#334155', fontFamily: 'var(--mono)', fontSize: 11 }}>
                No commands sent yet. Select a station and try Start/Stop.
              </div>
            ) : cmdLog.map(entry => (
              <div key={entry.id} style={{ padding: '6px 16px', fontFamily: 'var(--mono)', fontSize: 11, color: entry.type === 'error' ? '#f87171' : entry.type === 'success' ? '#4ade80' : '#94a3b8', display: 'flex', gap: 8 }}>
                <span style={{ color: '#334155', flexShrink: 0 }}>{entry.at}</span>
                <span style={{ color: entry.type === 'error' ? '#ef4444' : entry.type === 'success' ? '#22c55e' : '#f59e0b' }}>
                  {entry.type === 'error' ? '✗' : entry.type === 'success' ? '✓' : '→'}
                </span>
                <span style={{ wordBreak: 'break-all' }}>{entry.message}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

/* ═══════════════════════════════════════════════════════════
   MAIN DASHBOARD
═══════════════════════════════════════════════════════════ */
export default function AdminDashboard() {
  const [tab, setTab] = useState('overview');
  const [stats, setStats] = useState({ revenue: 0, energy: 0, users: 0, totalStations: 0 });
  const [users, setUsers] = useState([]);
  const [stations, setStations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [spinning, setSpinning] = useState(false);
  const [synced, setSynced] = useState(null);
  const [search, setSearch] = useState('');
  const [stationSearch, setStationSearch] = useState('');
  const [showAddModal, setShowAddModal] = useState(false);
  const [editingStation, setEditingStation] = useState(null);
  const [userFilter, setUserFilter] = useState('all');

  // Live WebSocket connection
  const { connected: wsConnected, liveChargers, logs: wsLogs, clearLogs } = useAdminSocket(BACKEND_URL);

  // Fetch Firestore data
  const fetchData = useCallback(async () => {
    setSpinning(true);
    try {
      const [usersSnap, bookingsSnap, stationsSnap] = await Promise.all([
        getDocs(collection(db, 'users')),
        getDocs(collection(db, 'bookings')),
        getDocs(collection(db, 'stations')),
      ]);
      const usersList = usersSnap.docs.map(d => ({ id: d.id, ...d.data() }));
      let revenue = 0, energy = 0;
      const bookings = [];
      bookingsSnap.forEach(d => {
        const data = d.data();
        revenue += data.amount || data.paidAmount || data.billTotal || data.energyCharge || 0;
        energy += data.energykWh || 5.5;
        bookings.push({ id: d.id, ...data });
      });
      const enriched = usersList.map(user => {
        const ub = bookings.filter(b => b.userId === user.id)
          .sort((a, b) => (b.timestamp?.toMillis?.() || 0) - (a.timestamp?.toMillis?.() || 0));
        return { ...user, totalBookings: ub.length, latestBooking: ub[0] || null };
      });
      const stationsList = stationsSnap.docs.map(d => ({ id: d.id, ...d.data() }));
      setStats({ revenue, energy, users: usersSnap.size, totalStations: stationsSnap.size });
      setUsers(enriched);
      setStations(stationsList);
      setSynced(new Date());
    } catch (e) { console.error(e); }
    finally { setLoading(false); setSpinning(false); }
  }, []);

  useEffect(() => { fetchData(); }, [fetchData]);

  // Station CRUD
  const handleSaveStation = async (form) => {
    const res = await fetch(`${BACKEND_URL}/admin/stations`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(form),
    });
    if (!res.ok) throw new Error('Failed to save station');
    await fetchData();
  };

  const handleUpdateStation = async (form) => {
    const { stationId, ...rest } = form;
    const res = await fetch(`${BACKEND_URL}/admin/stations/${stationId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(rest),
    });
    if (!res.ok) throw new Error('Failed to update station');
    await fetchData();
  };

  const handleDeleteStation = async (stationId) => {
    if (!window.confirm(`Delete station "${stationId}"?`)) return;
    const res = await fetch(`${BACKEND_URL}/admin/stations/${stationId}`, { method: 'DELETE' });
    if (!res.ok) throw new Error('Failed to delete station');
    await fetchData();
  };

  const handleTogglePublish = async (station) => {
    await fetch(`${BACKEND_URL}/admin/stations/${station.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ published: !station.published }),
    });
    await fetchData();
  };

  // Filtered data
  const nonAdminUsers = users.filter(u => u.role !== 'admin');
  const filteredUsers = nonAdminUsers
    .filter(u => userFilter === 'all' ? true : userFilter === 'active' ? u.totalBookings > 0 : u.totalBookings === 0)
    .filter(u => {
      const q = search.toLowerCase();
      return !q || (u.name || '').toLowerCase().includes(q) || (u.email || '').toLowerCase().includes(q);
    });

  const filteredStations = stations.filter(s => {
    const q = stationSearch.toLowerCase();
    return !q || (s.name || '').toLowerCase().includes(q) || (s.id || '').toLowerCase().includes(q) || (s.ocppStationId || '').toLowerCase().includes(q);
  });

  const onlineCount = liveChargers.filter(c => c.connected).length;

  const ticker = [
    'ADMIN COMMAND CENTER', `${onlineCount} CHARGERS ONLINE`,
    `${stats.totalStations} TOTAL STATIONS`, `${nonAdminUsers.length} REGISTERED USERS`,
    `₹${stats.revenue.toLocaleString('en-IN')} REVENUE`, `${stats.energy.toFixed(1)} kWh DELIVERED`,
    wsConnected ? 'TELEMETRY STREAM ACTIVE' : 'TELEMETRY DISCONNECTED',
  ];

  const statCards = [
    { title: 'Total Revenue', icon: IndianRupee, color: '#16a34a', bg: '#f0fdf4', accent: 'green', to: stats.revenue, prefix: '₹' },
    { title: 'Energy Supplied', icon: BatteryCharging, color: '#16a34a', bg: '#f0fdf4', accent: 'green', to: stats.energy, suffix: ' kWh', decimals: 1 },
    { title: 'Registered Users', icon: Users, color: '#16a34a', bg: '#f0fdf4', accent: 'green', to: nonAdminUsers.length },
    { title: 'Chargers Online', icon: Activity, color: '#16a34a', bg: '#f0fdf4', accent: 'green', to: onlineCount },
  ];

  const tabs = [
    { id: 'overview', label: 'Overview', icon: <LayoutGrid size={14} /> },
    { id: 'stations', label: 'Stations', icon: <Server size={14} /> },
    { id: 'users', label: 'Users', icon: <Users size={14} /> },
    // { id: 'commands', label: 'Commands', icon: <Terminal size={14} /> },
    // { id: 'logs', label: 'Live Logs', icon: <ScrollText size={14} /> },
  ];

  const avatarStyle = id => {
    const hue = ((id?.charCodeAt?.(0) || 65) * 47) % 360;
    return { bg: `hsl(${hue},70%,92%)`, color: '#0f172a' };
  };

  return (
    <div style={{ minHeight: '100vh', background: '#fff', fontFamily: 'var(--display)' }}>
      <style>{CSS}</style>

      {/* ══════ HERO HEADER ══════ */}
      <header style={{ background: '#0f172a', position: 'relative', overflow: 'hidden', paddingTop: 96, paddingBottom: 72 }}>
        <div style={{ position: 'absolute', inset: 0, backgroundImage: 'linear-gradient(rgba(255,255,255,0.035) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.035) 1px, transparent 1px)', backgroundSize: '40px 40px' }} />
        <div className="admin-scan-wipe" style={{ position: 'absolute', top: 0, bottom: 0, width: 2, background: 'linear-gradient(to bottom, transparent, #16a34a, transparent)', opacity: 0.45, zIndex: 1 }} />
        <div style={{ position: 'absolute', bottom: -12, left: 0, fontFamily: 'var(--display)', fontSize: '16vw', fontWeight: 900, color: 'rgba(255,255,255,0.03)', letterSpacing: '-0.06em', userSelect: 'none', whiteSpace: 'nowrap', zIndex: 0, lineHeight: 1 }}>ADMIN</div>

        <div style={{ maxWidth: 1280, margin: '0 auto', padding: '0 32px', position: 'relative', zIndex: 10 }}>
          <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', alignItems: 'flex-end', gap: 32 }}>
            <motion.div initial={{ opacity: 0, x: -30 }} animate={{ opacity: 1, x: 0 }} transition={{ duration: 0.9, ease: [0.16, 1, 0.3, 1] }}>
              {/* Status pill */}
              <div style={{ display: 'inline-flex', alignItems: 'center', gap: 10, padding: '8px 18px', borderRadius: 99, border: '2px solid rgba(255,255,255,0.12)', background: 'rgba(255,255,255,0.06)', marginBottom: 28, backdropFilter: 'blur(12px)', boxShadow: '0 4px 12px rgba(22, 163, 74, 0.15)' }}>
                <span className="admin-pulse-dot" style={{ width: 8, height: 8, borderRadius: '50%', background: wsConnected ? '#16a34a' : '#ef4444', display: 'inline-block', flexShrink: 0 }} />
                <span style={{ fontFamily: 'var(--mono)', fontSize: 10, fontWeight: 700, color: wsConnected ? '#4ade80' : '#f87171', letterSpacing: '0.14em' }}>
                  {wsConnected ? 'TELEMETRY STREAM ACTIVE' : 'TELEMETRY RECONNECTING'}
                </span>
              </div>

              <h1 style={{ fontFamily: 'var(--display)', fontSize: 'clamp(2.4rem, 5.5vw, 4.2rem)', fontWeight: 900, color: '#fff', lineHeight: 0.96, letterSpacing: '-0.04em', margin: '0 0 20px' }}>
                Admin<br />
                <span style={{ color: '#16a34a' }}>Dashboard</span>
              </h1>

              <p style={{ color: '#64748b', fontSize: '1.05rem', lineHeight: 1.65, maxWidth: 460, margin: 0 }}>
                Full control over stations, users, live telemetry &amp; OCPP commands — unified in one terminal.
              </p>

              {synced && (
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 20 }}>
                  <Clock size={12} color="#475569" />
                  <span style={{ fontFamily: 'var(--mono)', fontSize: 10, color: '#475569', fontWeight: 700, letterSpacing: '0.08em' }}>
                    LAST SYNC {synced.toLocaleTimeString()}
                  </span>
                  <button onClick={fetchData} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#16a34a', display: 'flex', padding: 0, marginLeft: 4 }}>
                    <RefreshCw size={13} style={{ animation: spinning ? 'admin-spin 0.9s linear infinite' : 'none' }} />
                  </button>
                </div>
              )}
            </motion.div>

            {/* Right: telemetry cards */}
            <motion.div className="admin-hero-right" initial={{ opacity: 0, x: 30 }} animate={{ opacity: 1, x: 0 }} transition={{ duration: 0.9, delay: 0.18 }}
              style={{ display: 'flex', gap: 14, flexWrap: 'wrap' }}>
              {[
                { label: 'WS Clients', value: wsConnected ? 'Active' : 'Down', icon: Radio, color: wsConnected ? '#4ade80' : '#f87171', bar: wsConnected ? 100 : 20 },
                { label: 'Chargers Online', value: `${onlineCount}`, icon: Cpu, color: '#16a34a', bar: stats.totalStations > 0 ? (onlineCount / stats.totalStations * 100) : 0 },
                { label: 'Total Stations', value: `${stats.totalStations}`, icon: Server, color: '#16a34a', bar: 100 },
              ].map((item, i) => (
                <div key={i} style={{ background: 'rgba(255,255,255,0.06)', border: '2px solid rgba(255,255,255,0.10)', borderRadius: 18, padding: '18px 22px', backdropFilter: 'blur(16px)', minWidth: 148, boxShadow: '4px 4px 0 rgba(255,255,255,0.04)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
                    <item.icon size={14} color={item.color} />
                    <span style={{ fontFamily: 'var(--mono)', fontSize: 9, fontWeight: 700, color: '#475569', letterSpacing: '0.1em', textTransform: 'uppercase' }}>{item.label}</span>
                  </div>
                  <div style={{ fontFamily: 'var(--display)', fontSize: '1.5rem', fontWeight: 900, color: '#fff', marginBottom: 12 }}>{item.value}</div>
                  <div style={{ height: 3, background: 'rgba(255,255,255,0.08)', borderRadius: 2, overflow: 'hidden' }}>
                    <motion.div initial={{ width: 0 }} animate={{ width: `${item.bar}%` }} transition={{ delay: 0.6 + i * 0.1, duration: 1 }}
                       style={{ height: '100%', background: item.color, borderRadius: 2 }} />
                  </div>
                </div>
              ))}
            </motion.div>
          </div>
        </div>
        <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: 1, background: 'linear-gradient(to right, transparent, #334155, transparent)' }} />
      </header>

      {/* ══════ TICKER ══════ */}
      <Ticker items={ticker} />

      {/* ══════ TABS + MAIN CONTENT ══════ */}
      <div style={{ position: 'relative' }}>
        <div className="admin-grid-lines" style={{ position: 'absolute', inset: 0, zIndex: 0, pointerEvents: 'none', opacity: 0.7 }} />

        <div style={{ maxWidth: 1280, margin: '0 auto', padding: '40px 32px 88px', position: 'relative', zIndex: 1 }}>

          {/* Tab Bar */}
          <div style={{ display: 'flex', gap: 8, marginBottom: 32, overflowX: 'auto', padding: '4px 0' }}>
            {tabs.map(t => (
              <button key={t.id} className={`admin-tab-btn ${tab === t.id ? 'active' : ''}`} onClick={() => setTab(t.id)}>
                {t.icon} {t.label}
              </button>
            ))}
          </div>

          {/* ══════ OVERVIEW TAB ══════ */}
          {tab === 'overview' && (
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
              {/* Stat Cards */}
              <div className="admin-stat-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 20, marginBottom: 48 }}>
                {statCards.map(({ title, icon: Icon, color, bg, accent, to, prefix = '', suffix = '', decimals = 0 }, i) => (
                  <motion.div key={title} className={`admin-neo-card stat-accent-${accent}`}
                    initial={{ opacity: 0, y: 24 }} animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.1 + i * 0.08, duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
                    style={{ borderRadius: 20, padding: '28px 26px', position: 'relative', overflow: 'hidden' }}>
                    <div style={{ position: 'absolute', top: 0, right: 0, width: 80, height: 80, background: color, opacity: 0.06, borderRadius: '0 18px 0 80px' }} />
                    <div style={{ width: 50, height: 50, borderRadius: 14, background: bg, border: `2px solid ${color}`, display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 20, boxShadow: `3px 3px 0 ${color}` }}>
                      <Icon size={22} color={color} />
                    </div>
                    <p style={{ fontFamily: 'var(--mono)', fontSize: 10, fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '0.1em', marginBottom: 6 }}>{title}</p>
                    <div style={{ fontFamily: 'var(--display)', fontSize: '2rem', fontWeight: 900, color: '#0f172a', letterSpacing: '-0.03em', lineHeight: 1 }}>
                      <Counter to={to} prefix={prefix} suffix={suffix} decimals={decimals} />
                    </div>
                  </motion.div>
                ))}
              </div>

              {/* Quick Station Overview */}
              <div style={{ background: '#fff', border: '2px solid #0f172a', borderRadius: 24, boxShadow: '8px 8px 0 #0f172a', overflow: 'hidden' }}>
                <div style={{ padding: '22px 28px', borderBottom: '2px solid #0f172a', display: 'flex', alignItems: 'center', justifyContent: 'space-between', background: '#fafafa' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    <div style={{ width: 44, height: 44, borderRadius: 12, background: '#eff6ff', border: '1px solid #bfdbfe', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Server size={20} color="#2563eb" />
                    </div>
                    <div>
                      <h2 style={{ fontFamily: 'var(--display)', fontWeight: 900, fontSize: '1.3rem', color: '#0f172a', margin: 0 }}>Station Overview</h2>
                      <span style={{ fontFamily: 'var(--mono)', fontSize: 9, color: '#94a3b8', fontWeight: 700, letterSpacing: '0.1em' }}>
                        {onlineCount} ONLINE / {stations.length} TOTAL
                      </span>
                    </div>
                  </div>
                  <button className="admin-btn admin-btn-ghost" onClick={() => setTab('stations')}>
                    View All <ChevronRight size={13} />
                  </button>
                </div>

                <div style={{ padding: 24 }}>
                  {loading ? (
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))', gap: 16 }}>
                      {[1,2,3].map(i => <div key={i} className="admin-shimmer" style={{ height: 120, borderRadius: 14 }} />)}
                    </div>
                  ) : stations.length === 0 ? (
                    <div style={{ padding: 40, textAlign: 'center' }}>
                      <Server size={32} color="#e2e8f0" style={{ margin: '0 auto 12px' }} />
                      <p style={{ fontFamily: 'var(--mono)', fontSize: 11, color: '#94a3b8', fontWeight: 700 }}>NO STATIONS REGISTERED</p>
                    </div>
                  ) : (
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))', gap: 16 }}>
                      {stations.slice(0, 6).map(s => {
                        const live = liveChargers.find(c => c.id === (s.ocppStationId || s.id));
                        const isOnline = live?.connected || s.isOnline;
                        return (
                          <div key={s.id} className="admin-station-card">
                            <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 3, background: isOnline ? '#16a34a' : '#e2e8f0', borderRadius: '16px 16px 0 0' }} />
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
                              <div>
                                <div style={{ fontFamily: 'var(--display)', fontWeight: 800, fontSize: 14, color: '#0f172a', marginBottom: 2 }}>
                                  {s.name || s.id}
                                </div>
                                <div style={{ fontFamily: 'var(--mono)', fontSize: 10, color: '#94a3b8' }}>{s.ocppStationId || s.id}</div>
                              </div>
                              <OnlineBadge online={isOnline} />
                            </div>
                            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                              <StatusBadge status={live?.status || s.status} />
                              <span className="admin-badge" style={{ color: '#64748b', background: '#f8fafc', borderColor: '#e2e8f0' }}>
                                {s.chargerType || 'N/A'}
                              </span>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>
              </div>
            </motion.div>
          )}

          {/* ══════ STATIONS TAB ══════ */}
          {tab === 'stations' && (
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
              <div style={{ background: '#fff', border: '2px solid #0f172a', borderRadius: 24, boxShadow: '8px 8px 0 #0f172a', overflow: 'hidden' }}>
                {/* Header */}
                <div style={{ padding: '22px 28px', borderBottom: '2px solid #0f172a', display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: 14, background: '#fafafa' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginRight: 'auto' }}>
                    <div style={{ width: 44, height: 44, borderRadius: 12, background: '#eff6ff', border: '1px solid #bfdbfe', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Server size={20} color="#2563eb" />
                    </div>
                    <div>
                      <h2 style={{ fontFamily: 'var(--display)', fontWeight: 900, fontSize: '1.3rem', color: '#0f172a', margin: 0 }}>Station Management</h2>
                      <span style={{ fontFamily: 'var(--mono)', fontSize: 9, color: '#94a3b8', fontWeight: 700, letterSpacing: '0.1em' }}>
                        {filteredStations.length} / {stations.length} STATIONS
                      </span>
                    </div>
                  </div>

                  <div className="admin-search-wrap admin-hide-sm" style={{ width: 220 }}>
                    <Search size={14} color="#94a3b8" />
                    <input placeholder="Search stations…" value={stationSearch} onChange={e => setStationSearch(e.target.value)} />
                  </div>

                  <button className="admin-btn admin-btn-primary" onClick={() => { setEditingStation(null); setShowAddModal(true); }}>
                    <Plus size={13} /> Add Station
                  </button>
                </div>

                {/* Table */}
                <div style={{ overflowX: 'auto' }}>
                  <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                      <tr style={{ borderBottom: '2px solid #f1f5f9' }}>
                        {['Station', 'Type', 'Status', 'Online', 'Published', 'Rate', 'Actions'].map(h => (
                          <th key={h} style={{ padding: '13px 16px', fontFamily: 'var(--mono)', fontSize: 9, fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '0.14em', textAlign: 'left', background: '#fafafa' }}>{h}</th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      {loading ? Array.from({ length: 4 }).map((_, i) => (
                        <tr key={i} style={{ borderBottom: '1px solid #f1f5f9' }}>
                          {[40, 15, 15, 12, 12, 12, 20].map((w, j) => (
                            <td key={j} style={{ padding: '16px' }}><div className="admin-shimmer" style={{ height: 13, borderRadius: 4, width: `${w}%` }} /></td>
                          ))}
                        </tr>
                      )) : filteredStations.length === 0 ? (
                        <tr><td colSpan={7} style={{ padding: 60, textAlign: 'center' }}>
                          <Server size={32} color="#e2e8f0" style={{ margin: '0 auto 12px' }} />
                          <p style={{ fontFamily: 'var(--mono)', fontSize: 11, color: '#94a3b8', fontWeight: 700 }}>NO STATIONS FOUND</p>
                        </td></tr>
                      ) : filteredStations.map((s, idx) => {
                        const live = liveChargers.find(c => c.id === (s.ocppStationId || s.id));
                        const isOnline = live?.connected || s.isOnline;
                        return (
                          <motion.tr key={s.id} className="admin-trow"
                            initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }}
                            transition={{ delay: 0.03 * idx }}
                            style={{ borderBottom: '1px solid #f8fafc' }}>
                            <td style={{ padding: '16px' }}>
                              <div style={{ fontFamily: 'var(--display)', fontWeight: 700, fontSize: 14, color: '#0f172a' }}>{s.name || s.id}</div>
                              <div style={{ fontFamily: 'var(--mono)', fontSize: 10, color: '#94a3b8' }}>{s.ocppStationId || s.id}</div>
                            </td>
                            <td style={{ padding: '16px' }}>
                              <span className="admin-badge" style={{ color: '#64748b', background: '#f8fafc', borderColor: '#e2e8f0' }}>{s.chargerType || 'N/A'}</span>
                            </td>
                            <td style={{ padding: '16px' }}>
                              <StatusBadge status={live?.status || s.status} />
                            </td>
                            <td style={{ padding: '16px' }}>
                              <OnlineBadge online={isOnline} />
                            </td>
                            <td style={{ padding: '16px' }}>
                              <button onClick={() => handleTogglePublish(s)}
                                style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 4, color: s.published ? '#16a34a' : '#94a3b8' }}>
                                {s.published ? <Eye size={14} /> : <EyeOff size={14} />}
                                <span style={{ fontFamily: 'var(--mono)', fontSize: 10, fontWeight: 700 }}>{s.published ? 'YES' : 'NO'}</span>
                              </button>
                            </td>
                            <td style={{ padding: '16px' }}>
                              <span style={{ fontFamily: 'var(--mono)', fontSize: 11, color: '#334155', fontWeight: 700 }}>₹{s.energyRatePerKwh || 0}/kWh</span>
                            </td>
                            <td style={{ padding: '16px' }}>
                              <div style={{ display: 'flex', gap: 6 }}>
                                <button className="admin-btn admin-btn-ghost" style={{ padding: '6px 10px', fontSize: 10 }}
                                  onClick={() => { setEditingStation(s); setShowAddModal(true); }}>
                                  <Edit3 size={12} />
                                </button>
                                <button className="admin-btn admin-btn-danger" style={{ padding: '6px 10px', fontSize: 10 }}
                                  onClick={() => handleDeleteStation(s.id)}>
                                  <Trash2 size={12} />
                                </button>
                              </div>
                            </td>
                          </motion.tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>

                {!loading && (
                  <div style={{ padding: '14px 28px', borderTop: '2px solid #f1f5f9', background: '#fafafa', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontFamily: 'var(--mono)', fontSize: 9, color: '#94a3b8', fontWeight: 700, letterSpacing: '0.1em' }}>
                      {filteredStations.length} STATIONS
                    </span>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <div className={wsConnected ? 'admin-pulse-dot' : ''} style={{ width: 6, height: 6, borderRadius: '50%', background: wsConnected ? '#16a34a' : '#94a3b8' }} />
                      <span style={{ fontFamily: 'var(--mono)', fontSize: 9, color: '#64748b', fontWeight: 700, letterSpacing: '0.08em' }}>
                        {wsConnected ? 'LIVE SYNC' : 'OFFLINE'}
                      </span>
                    </div>
                  </div>
                )}
              </div>
            </motion.div>
          )}

          {/* ══════ USERS TAB ══════ */}
          {tab === 'users' && (
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
              <div style={{ background: '#fff', border: '2px solid #0f172a', borderRadius: 24, boxShadow: '8px 8px 0 #0f172a', overflow: 'hidden' }}>
                <div style={{ padding: '22px 28px', borderBottom: '2px solid #0f172a', display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: 14, background: '#fafafa' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginRight: 'auto' }}>
                    <div style={{ width: 44, height: 44, borderRadius: 12, background: '#ede9fe', border: '1px solid #ddd6fe', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Users size={20} color="#7c3aed" />
                    </div>
                    <div>
                      <h2 style={{ fontFamily: 'var(--display)', fontWeight: 900, fontSize: '1.3rem', color: '#0f172a', margin: 0 }}>User Directory</h2>
                      <span style={{ fontFamily: 'var(--mono)', fontSize: 9, color: '#94a3b8', fontWeight: 700, letterSpacing: '0.1em' }}>
                        {filteredUsers.length} / {nonAdminUsers.length} USERS
                      </span>
                    </div>
                  </div>

                  <div className="admin-search-wrap admin-hide-sm" style={{ width: 220 }}>
                    <Search size={14} color="#94a3b8" />
                    <input placeholder="Search users…" value={search} onChange={e => setSearch(e.target.value)} />
                  </div>

                  <div style={{ display: 'flex', gap: 6, background: '#f1f5f9', padding: 4, borderRadius: 10, border: '1px solid var(--border)' }}>
                    {['all', 'active', 'inactive'].map(f => (
                      <button key={f} className="admin-tab-btn" style={{ padding: '6px 14px', fontSize: 10, ...(userFilter === f ? { background: '#0f172a', color: '#fff' } : {}) }}
                        onClick={() => setUserFilter(f)}>{f}</button>
                    ))}
                  </div>
                </div>

                <div style={{ overflowX: 'auto' }}>
                  <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                      <tr style={{ borderBottom: '2px solid #f1f5f9' }}>
                        {['User Details', 'Role', 'Bookings', 'Wallet', 'Latest Station', 'Payment'].map(h => (
                          <th key={h} style={{ padding: '13px 16px', fontFamily: 'var(--mono)', fontSize: 9, fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '0.14em', textAlign: 'left', background: '#fafafa' }}>{h}</th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      {loading ? Array.from({ length: 5 }).map((_, i) => (
                        <tr key={i} style={{ borderBottom: '1px solid #f1f5f9' }}>
                          {[40, 10, 12, 12, 20, 15].map((w, j) => (
                            <td key={j} style={{ padding: '16px' }}><div className="admin-shimmer" style={{ height: 13, borderRadius: 4, width: `${w}%` }} /></td>
                          ))}
                        </tr>
                      )) : filteredUsers.length === 0 ? (
                        <tr><td colSpan={6} style={{ padding: 60, textAlign: 'center' }}>
                          <Globe size={32} color="#e2e8f0" style={{ margin: '0 auto 12px' }} />
                          <p style={{ fontFamily: 'var(--mono)', fontSize: 11, color: '#94a3b8', fontWeight: 700 }}>NO USERS MATCH</p>
                        </td></tr>
                      ) : filteredUsers.map((u, idx) => {
                        const av = avatarStyle(u.id);
                        return (
                          <motion.tr key={u.id} className="admin-trow"
                            initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }}
                            transition={{ delay: 0.03 * idx }}
                            style={{ borderBottom: '1px solid #f8fafc' }}>
                            <td style={{ padding: '16px' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                                <div style={{ width: 38, height: 38, borderRadius: 10, background: av.bg, color: av.color, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'var(--display)', fontWeight: 900, fontSize: 15, border: '1.5px solid var(--border)', flexShrink: 0 }}>
                                  {(u.name || u.email || 'A').charAt(0).toUpperCase()}
                                </div>
                                <div>
                                  <div style={{ fontFamily: 'var(--display)', fontWeight: 700, fontSize: 14, color: '#0f172a' }}>{u.name || 'Anonymous'}</div>
                                  <div style={{ fontFamily: 'var(--mono)', fontSize: 10, color: '#94a3b8' }}>{u.email}</div>
                                </div>
                              </div>
                            </td>
                            <td style={{ padding: '16px' }}>
                              <span className="admin-badge" style={{ color: u.role === 'admin' ? '#dc2626' : '#2563eb', background: u.role === 'admin' ? '#fef2f2' : '#eff6ff', borderColor: u.role === 'admin' ? '#dc2626' : '#2563eb' }}>
                                {u.role || 'user'}
                              </span>
                            </td>
                            <td style={{ padding: '16px' }}>
                              <span style={{ fontFamily: 'var(--mono)', fontWeight: 900, fontSize: 13, color: u.totalBookings > 0 ? '#16a34a' : '#cbd5e1', background: u.totalBookings > 0 ? '#f0fdf4' : '#f8fafc', border: `1px solid ${u.totalBookings > 0 ? '#16a34a' : '#e2e8f0'}`, borderRadius: 8, padding: '4px 14px', display: 'inline-block' }}>
                                {u.totalBookings}
                              </span>
                            </td>
                            <td style={{ padding: '16px' }}>
                              <span style={{ fontFamily: 'var(--display)', fontWeight: 800, fontSize: 14, color: '#0f172a' }}>
                                ₹{(u.walletBalance || 0).toFixed(2)}
                              </span>
                            </td>
                            <td style={{ padding: '16px' }}>
                              {u.latestBooking ? (
                                <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
                                  <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#16a34a', flexShrink: 0 }} />
                                  <span style={{ fontFamily: 'var(--mono)', fontSize: 11, color: '#334155', maxWidth: 140, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                                    {u.latestBooking.stationId || u.latestBooking.stationName || 'N/A'}
                                  </span>
                                </div>
                              ) : <span style={{ fontFamily: 'var(--mono)', fontSize: 9, color: '#cbd5e1', letterSpacing: '0.1em' }}>NO ACTIVITY</span>}
                            </td>
                            <td style={{ padding: '16px' }}>
                              {u.latestBooking ? (
                                <span style={{ fontFamily: 'var(--display)', fontWeight: 900, fontSize: 15, color: '#0f172a' }}>
                                  ₹{(u.latestBooking.amount || u.latestBooking.paidAmount || u.latestBooking.billTotal || u.latestBooking.energyCharge || 0).toLocaleString('en-IN')}
                                </span>
                              ) : <span style={{ fontFamily: 'var(--mono)', fontSize: 10, color: '#e2e8f0' }}>—</span>}
                            </td>
                          </motion.tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>

                {!loading && (
                  <div style={{ padding: '14px 28px', borderTop: '2px solid #f1f5f9', background: '#fafafa', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontFamily: 'var(--mono)', fontSize: 9, color: '#94a3b8', fontWeight: 700, letterSpacing: '0.1em' }}>
                      SHOWING {filteredUsers.length} OF {nonAdminUsers.length} USERS
                    </span>
                  </div>
                )}
              </div>
            </motion.div>
          )}

          {/* ══════ COMMANDS TAB (Disabled) ══════ */}
          {/*
          {tab === 'commands' && (
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
              <CommandCenter stations={stations} liveChargers={liveChargers} />
            </motion.div>
          )}
          */}

          {/* ══════ LIVE LOGS TAB (Disabled) ══════ */}
          {/*
          {tab === 'logs' && (
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
              <div style={{ background: '#0f172a', border: '2px solid #0f172a', borderRadius: 24, boxShadow: '8px 8px 0 var(--gold)', overflow: 'hidden' }}>
                <div style={{ padding: '18px 24px', borderBottom: '1px solid #1e293b', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <div className={wsConnected ? 'admin-pulse-dot' : ''} style={{ width: 8, height: 8, borderRadius: '50%', background: wsConnected ? '#16a34a' : '#ef4444' }} />
                    <span style={{ fontFamily: 'var(--mono)', fontSize: 12, fontWeight: 700, color: '#fbbf24', letterSpacing: '0.08em' }}>
                      LIVE TELEMETRY STREAM
                    </span>
                    <span style={{ fontFamily: 'var(--mono)', fontSize: 10, color: '#475569' }}>
                      ({wsLogs.length} events)
                    </span>
                  </div>
                  <button onClick={clearLogs} style={{ background: 'none', border: '1px solid #334155', borderRadius: 6, padding: '4px 12px', color: '#64748b', cursor: 'pointer', fontFamily: 'var(--mono)', fontSize: 9, fontWeight: 700 }}>CLEAR</button>
                </div>

                <div style={{ maxHeight: 600, overflowY: 'auto' }}>
                  {wsLogs.length === 0 ? (
                    <div style={{ padding: 60, textAlign: 'center', color: '#334155', fontFamily: 'var(--mono)', fontSize: 12 }}>
                      {wsConnected ? 'Waiting for telemetry events...' : 'Connecting to telemetry stream...'}
                    </div>
                  ) : wsLogs.map(log => {
                    const typeColors = {
                      system: '#60a5fa', connect: '#4ade80', disconnect: '#f87171',
                      status: '#fbbf24', heartbeat: '#94a3b8', meter: '#a78bfa', unknown: '#64748b',
                    };
                    return (
                      <div key={log.id} style={{ padding: '8px 20px', borderBottom: '1px solid #1e293b', fontFamily: 'var(--mono)', fontSize: 11, display: 'flex', gap: 12, alignItems: 'flex-start' }}>
                        <span style={{ color: '#334155', flexShrink: 0, minWidth: 70 }}>
                          {new Date(log.receivedAt).toLocaleTimeString()}
                        </span>
                        <span style={{ color: typeColors[log.type] || '#64748b', fontWeight: 700, flexShrink: 0, minWidth: 90, textTransform: 'uppercase', fontSize: 9, paddingTop: 1 }}>
                          [{log.type}]
                        </span>
                        <span style={{ color: '#94a3b8', wordBreak: 'break-all' }}>{log.message}</span>
                      </div>
                    );
                  })}
                </div>
              </div>
            </motion.div>
          )}
          */}
        </div>
      </div>

      {/* ══════ ADD/EDIT STATION MODAL ══════ */}
      <AnimatePresence>
        {showAddModal && (
          <AddStationModal
            editing={editingStation}
            onClose={() => { setShowAddModal(false); setEditingStation(null); }}
            onSave={editingStation ? handleUpdateStation : handleSaveStation}
          />
        )}
      </AnimatePresence>
    </div>
  );
}