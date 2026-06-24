import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { motion, AnimatePresence } from 'framer-motion';
import { User as UserIcon, Mail, Wallet, ShieldCheck, Smartphone, X, Save, Loader2, Activity, Cpu, Radio, Globe, Copy, Check, IndianRupee } from 'lucide-react';
import { doc, updateDoc, collection, getDocs } from 'firebase/firestore';
import { updateProfile } from 'firebase/auth';
import { db, auth } from '../lib/firebase';
import toast from 'react-hot-toast';

/* ─── GLOBAL STYLES (matching HeroSection) ─── */
const GLOBAL_CSS = `
  :root {
    --font-display: 'Clash Display', 'Cabinet Grotesk', system-ui, sans-serif;
    --font-body:    'Cabinet Grotesk', system-ui, sans-serif;
  }
  .grid-lines {
    background-image:
      linear-gradient(rgba(15,23,42,0.04) 1px, transparent 1px),
      linear-gradient(90deg, rgba(15,23,42,0.04) 1px, transparent 1px);
    background-size: 40px 40px;
  }
  .glass-card {
    background: rgba(255,255,255,0.82);
    backdrop-filter: blur(24px);
    -webkit-backdrop-filter: blur(24px);
    border: 2px solid #0f172a;
    box-shadow: 10px 10px 0 rgba(15,23,42,0.08);
  }
  @keyframes scan-line-wipe {
    0%   { left: -10%; opacity: 0; }
    5%   { opacity: 1; }
    95%  { opacity: 1; }
    100% { left: 110%; opacity: 0; }
  }
  @keyframes pulse-dot {
    0%, 100% { opacity: 1; transform: scale(1); }
    50%       { opacity: 0.5; transform: scale(1.4); }
  }
  .animate-scan-wipe { animation: scan-line-wipe 8s linear infinite; }
  .pulse-dot { animation: pulse-dot 2s ease-in-out infinite; }

  .profile-input {
    width: 100%;
    background: #f8fafc;
    border: 2px solid #e2e8f0;
    border-radius: 12px;
    padding: 10px 14px;
    font-family: var(--font-body);
    font-size: 14px;
    font-weight: 700;
    color: #0f172a;
    outline: none;
    transition: border-color 0.2s, box-shadow 0.2s;
    box-sizing: border-box;
  }
  .profile-input:focus {
    border-color: #16a34a;
    box-shadow: 4px 4px 0 rgba(22,163,74,0.15);
  }
  .profile-input:disabled {
    background: #f1f5f9;
    color: #94a3b8;
    cursor: not-allowed;
    border-color: #e2e8f0;
  }
`;

const Profile = () => {
  const { currentUser } = useAuth();
  const profile = currentUser?.profile || {};

  const [name, setName] = useState(profile.name || currentUser?.displayName || '');
  const [phone, setPhone] = useState(profile.phone || '');
  const [isSaving, setIsSaving] = useState(false);
  const [copiedUid, setCopiedUid] = useState(false);
  const [revenue, setRevenue] = useState(0);
  const [loadingRevenue, setLoadingRevenue] = useState(false);
  const [showAppModal, setShowAppModal] = useState(false);

  React.useEffect(() => {
    if (profile.role === 'admin') {
      const fetchRevenue = async () => {
        setLoadingRevenue(true);
        try {
          const bookingsSnap = await getDocs(collection(db, 'bookings'));
          let totalRevenue = 0;
          bookingsSnap.forEach(d => {
            const data = d.data();
            totalRevenue += data.amount || data.paidAmount || data.billTotal || data.energyCharge || 0;
          });
          setRevenue(totalRevenue);
        } catch (err) {
          console.error("Error fetching admin revenue in profile:", err);
        } finally {
          setLoadingRevenue(false);
        }
      };
      fetchRevenue();
    }
  }, [profile.role]);

  React.useEffect(() => {
    if (profile.name || currentUser?.displayName) {
      setName(profile.name || currentUser?.displayName || '');
    }
    if (profile.phone) {
      setPhone(profile.phone);
    }
  }, [profile.name, profile.phone, currentUser?.displayName]);

  const handleUpdateProfile = async (e) => {
    e.preventDefault();
    if (!name.trim()) return toast.error("Name cannot be empty");

    setIsSaving(true);
    try {
      await updateProfile(auth.currentUser, { displayName: name });
      const userRef = doc(db, 'users', currentUser.uid);
      await updateDoc(userRef, {
        name: name,
        phone: phone.trim()
      });
      toast.success("Profile updated successfully!");
    } catch (err) {
      console.error(err);
      toast.error("Failed to update profile");
    } finally {
      setIsSaving(false);
    }
  };

  const handleCopyUid = () => {
    if (!currentUser?.uid) return;
    navigator.clipboard.writeText(currentUser.uid);
    setCopiedUid(true);
    toast.success("UID copied to clipboard!");
    setTimeout(() => setCopiedUid(false), 2000);
  };

  return (
    <div style={{ minHeight: '100vh', background: '#fff', paddingTop: 96, paddingBottom: 64, position: 'relative', overflow: 'hidden' }}>
      <style>{GLOBAL_CSS}</style>

      {/* Background */}
      <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
        <div className="grid-lines" style={{ position: 'absolute', inset: 0, opacity: 0.8 }} />
        <div
          className="animate-scan-wipe"
          style={{ position: 'absolute', top: 0, bottom: 0, width: 2, background: 'linear-gradient(to bottom, transparent, #16a34a, transparent)', opacity: 0.4, zIndex: 1 }}
        />
        {/* Decorative text watermark */}
        <div style={{ position: 'absolute', top: '50%', left: '-2%', transform: 'translateY(-50%)', fontFamily: 'var(--font-display)', fontSize: '18vw', fontWeight: 900, color: '#f1f5f9', letterSpacing: '-0.05em', whiteSpace: 'nowrap', userSelect: 'none', pointerEvents: 'none' }}>
          ACCOUNT
        </div>
      </div>

      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '0 24px', position: 'relative', zIndex: 10 }}>

        {/* Page Header */}
        <motion.div initial={{ opacity: 0, y: -16 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }} style={{ marginBottom: 40 }}>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 10, padding: '7px 16px', borderRadius: 99, background: '#f8fafc', border: '2px solid #0f172a', marginBottom: 20 }}>
            <div className="pulse-dot" style={{ width: 8, height: 8, borderRadius: '50%', background: '#16a34a' }} />
            <span style={{ fontFamily: 'var(--font-body)', fontSize: 11, fontWeight: 800, color: '#0f172a', letterSpacing: '0.1em' }}>SYSTEM :: USER PROFILE</span>
          </div>
          <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 'clamp(2.5rem, 5vw, 4rem)', fontWeight: 800, color: '#0f172a', letterSpacing: '-0.04em', lineHeight: 0.95, margin: 0 }}>
            My Profile
          </h1>
        </motion.div>

        {/* Main Grid */}
        <div 
          style={{ gap: 32, alignItems: 'start' }}
          className="grid grid-cols-1 lg:grid-cols-[1.3fr_1fr]"
        >

          {/* LEFT COLUMN */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
            {/* Personal Info Card */}
            <motion.div
              initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
              style={{ background: '#fff', borderRadius: 28, border: '2px solid #0f172a', boxShadow: '10px 10px 0 rgba(15,23,42,0.07)', padding: 24, overflow: 'hidden', position: 'relative' }}
            >
              {/* Accent corner */}
              <div style={{ position: 'absolute', top: 0, right: 0, width: 60, height: 60, background: 'linear-gradient(135deg, #16a34a15, transparent)', borderBottomLeftRadius: 60, pointerEvents: 'none' }} />

              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 18, paddingBottom: 14, borderBottom: '1.5px solid #f1f5f9' }}>
                <div style={{ width: 36, height: 36, borderRadius: 12, background: '#0f172a', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1.5px solid #0f172a', flexShrink: 0 }}>
                  <UserIcon size={18} color="#16a34a" />
                </div>
                <div>
                  <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 18, fontWeight: 800, color: '#0f172a', margin: 0 }}>Personal Information</h2>
                  <p style={{ fontFamily: 'var(--font-body)', fontSize: 12, color: '#64748b', margin: 0, fontWeight: 600 }}>Update your account details</p>
                </div>
              </div>

              <form onSubmit={handleUpdateProfile}>
                <div 
                  style={{ gap: 16, marginBottom: 16 }}
                  className="grid grid-cols-1 sm:grid-cols-2"
                >
                  <div>
                    <label style={{ display: 'block', fontFamily: 'var(--font-body)', fontSize: 10, fontWeight: 800, color: '#64748b', letterSpacing: '0.08em', marginBottom: 6 }}>FULL NAME</label>
                    <input
                      type="text"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      className="profile-input"
                      placeholder="Enter your name"
                    />
                  </div>

                  <div>
                    <label style={{ display: 'block', fontFamily: 'var(--font-body)', fontSize: 10, fontWeight: 800, color: '#64748b', letterSpacing: '0.08em', marginBottom: 6 }}>CONTACT NUMBER</label>
                    <input
                      type="text"
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      className="profile-input"
                      placeholder="Enter phone number"
                    />
                  </div>
                </div>

                <div 
                  style={{ gap: 16, alignItems: 'flex-end' }}
                  className="grid grid-cols-1 md:grid-cols-[1.2fr_0.8fr]"
                >
                  <div>
                    <label style={{ display: 'block', fontFamily: 'var(--font-body)', fontSize: 10, fontWeight: 800, color: '#64748b', letterSpacing: '0.08em', marginBottom: 6 }}>REGISTERED EMAIL</label>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10, background: '#f1f5f9', border: '1.5px solid #e2e8f0', borderRadius: 12, padding: '10px 14px' }}>
                      <Mail size={14} color="#94a3b8" />
                      <span style={{ fontFamily: 'var(--font-body)', fontSize: 14, fontWeight: 700, color: '#94a3b8', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{currentUser?.email}</span>
                    </div>
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                    <motion.button
                      type="submit"
                      disabled={isSaving}
                      whileHover={{ y: -2, boxShadow: '6px 6px 0 #16a34a' }}
                      whileTap={{ scale: 0.98 }}
                      style={{ width: '100%', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6, padding: '11px 0', borderRadius: 12, background: '#0f172a', color: '#fff', border: '1.5px solid #0f172a', fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 13, cursor: isSaving ? 'not-allowed' : 'pointer', opacity: isSaving ? 0.75 : 1, boxShadow: '4px 4px 0 rgba(22,163,74,0.25)', transition: 'box-shadow 0.2s' }}
                    >
                      {isSaving ? <Loader2 size={14} style={{ animation: 'spin 1s linear infinite' }} /> : <Save size={14} />}
                      Update Profile
                    </motion.button>
                  </div>
                </div>
              </form>
            </motion.div>
          </div>

          {/* RIGHT COLUMN */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>

            {/* Wallet Card — only for non-admins */}
            {profile.role !== 'admin' ? (
              <motion.div
                initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7, delay: 0.15, ease: [0.16, 1, 0.3, 1] }}
                style={{ background: '#0f172a', borderRadius: 28, border: '2px solid #0f172a', boxShadow: '10px 10px 0 rgba(15,23,42,0.15)', padding: 24, position: 'relative', overflow: 'hidden' }}
              >
                {/* Glow blobs */}
                <div style={{ position: 'absolute', top: -40, right: -40, width: 140, height: 140, background: 'rgba(22,163,74,0.15)', borderRadius: '50%', filter: 'blur(35px)', pointerEvents: 'none' }} />

                <div style={{ position: 'relative', zIndex: 10 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: 'rgba(22,163,74,0.15)', border: '1.5px solid rgba(22,163,74,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Wallet size={16} color="#16a34a" />
                    </div>
                    <div>
                      <p style={{ fontFamily: 'var(--font-body)', fontSize: 10, fontWeight: 800, color: '#16a34a', letterSpacing: '0.1em', margin: 0 }}>CHARGE WALLET</p>
                      <p style={{ fontFamily: 'var(--font-body)', fontSize: 11, fontWeight: 700, color: '#94a3b8', margin: 0 }}>Available Balance</p>
                    </div>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginBottom: 24 }}>
                    <span style={{ fontFamily: 'var(--font-display)', fontSize: 22, fontWeight: 800, color: '#16a34a' }}>₹</span>
                    <span style={{ fontFamily: 'var(--font-display)', fontSize: 44, fontWeight: 900, color: '#fff', letterSpacing: '-0.03em', lineHeight: 1 }}>
                      {profile.walletBalance?.toFixed(2) || '0.00'}
                    </span>
                  </div>

                  <motion.button
                    onClick={() => setShowAppModal(true)}
                    whileHover={{ y: -2, boxShadow: '6px 6px 0 rgba(22,163,74,0.4)' }}
                    whileTap={{ scale: 0.98 }}
                    style={{ width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, padding: '12px 0', borderRadius: 12, background: '#16a34a', color: '#fff', border: '1.5px solid #16a34a', fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 13, cursor: 'pointer', boxShadow: '4px 4px 0 rgba(22,163,74,0.25)', transition: 'box-shadow 0.2s' }}
                  >
                    <Wallet size={14} /> Add Money via App
                  </motion.button>
                </div>
              </motion.div>
            ) : (
              <motion.div
                initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7, delay: 0.15, ease: [0.16, 1, 0.3, 1] }}
                style={{ background: '#fff', borderRadius: 28, border: '2px solid #0f172a', boxShadow: '10px 10px 0 rgba(15,23,42,0.07)', padding: 24, position: 'relative', overflow: 'hidden' }}
              >
                {/* Glow blobs */}
                <div style={{ position: 'absolute', top: -40, right: -40, width: 140, height: 140, background: 'rgba(22,163,74,0.12)', borderRadius: '50%', filter: 'blur(35px)', pointerEvents: 'none' }} />

                <div style={{ position: 'relative', zIndex: 10 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: 'rgba(22,163,74,0.15)', border: '1.5px solid rgba(22,163,74,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <IndianRupee size={16} color="#16a34a" />
                    </div>
                    <div>
                      <p style={{ fontFamily: 'var(--font-body)', fontSize: 10, fontWeight: 800, color: '#16a34a', letterSpacing: '0.1em', margin: 0 }}>NETWORK REVENUE</p>
                      <p style={{ fontFamily: 'var(--font-body)', fontSize: 11, fontWeight: 700, color: '#64748b', margin: 0 }}>Total Earnings</p>
                    </div>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginBottom: 24 }}>
                    <span style={{ fontFamily: 'var(--font-display)', fontSize: 22, fontWeight: 800, color: '#16a34a' }}>₹</span>
                    <span style={{ fontFamily: 'var(--font-display)', fontSize: 44, fontWeight: 900, color: '#0f172a', letterSpacing: '-0.03em', lineHeight: 1 }}>
                      {loadingRevenue ? (
                        <Loader2 size={24} style={{ animation: 'spin 1s linear infinite', color: '#0f172a' }} />
                      ) : (
                        revenue.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
                      )}
                    </span>
                  </div>

                  <div style={{ padding: '10px 14px', background: '#f8fafc', border: '1.5px solid #e2e8f0', borderRadius: 12, display: 'flex', alignItems: 'center', gap: 8 }}>
                    <Activity size={12} color="#16a34a" />
                    <span style={{ fontFamily: 'var(--font-body)', fontSize: 11, fontWeight: 700, color: '#64748b' }}>
                      Live sync active
                    </span>
                  </div>
                </div>
              </motion.div>
            )}
          </div>
        </div>
      </div>

      {/* App Redirection Modal */}
      <AnimatePresence>
        {showAppModal && (
          <>
            <motion.div
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              style={{ position: 'fixed', inset: 0, background: 'rgba(15,23,42,0.6)', backdropFilter: 'blur(8px)', zIndex: 40 }}
              onClick={() => setShowAppModal(false)}
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.94, y: 24 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.94, y: 24 }}
              transition={{ duration: 0.4, ease: [0.16, 1, 0.3, 1] }}
              style={{ position: 'fixed', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', maxWidth: 440, background: '#fff', borderRadius: 32, zIndex: 50, border: '2px solid #0f172a' }}
              className="w-[calc(100%-32px)] sm:w-full p-6 sm:p-10 shadow-[8px_8px_0_rgba(15,23,42,0.12)] sm:shadow-[16px_16px_0_rgba(15,23,42,0.12)]"
            >
              <button
                onClick={() => setShowAppModal(false)}
                style={{ position: 'absolute', top: 16, right: 16, width: 36, height: 36, borderRadius: '50%', background: '#f1f5f9', border: '1.5px solid #e2e8f0', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}
              >
                <X size={16} color="#64748b" />
              </button>

              <div style={{ width: 64, height: 64, background: '#0f172a', borderRadius: 20, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 24px', border: '2px solid #0f172a', boxShadow: '6px 6px 0 rgba(22,163,74,0.3)' }}>
                <Smartphone size={28} color="#16a34a" />
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: 8, justifyContent: 'center', marginBottom: 14 }}>
                <div className="pulse-dot" style={{ width: 7, height: 7, borderRadius: '50%', background: '#16a34a' }} />
                <span style={{ fontFamily: 'var(--font-body)', fontSize: 10, fontWeight: 800, color: '#64748b', letterSpacing: '0.1em' }}>SECURE CHANNEL</span>
              </div>

              <h3 style={{ fontFamily: 'var(--font-display)', fontSize: 28, fontWeight: 800, color: '#0f172a', textAlign: 'center', margin: '0 0 12px', letterSpacing: '-0.02em' }}>Open CogniBot App</h3>
              <p style={{ fontFamily: 'var(--font-body)', fontSize: 15, color: '#64748b', fontWeight: 600, textAlign: 'center', lineHeight: 1.6, margin: '0 0 32px' }}>
                For security and seamless UPI integration, please open the mobile app to top-up your wallet safely.
              </p>

              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                <motion.a
                  href="intent://evapp/#Intent;scheme=evapp;package=com.example.evApp;end"
                  whileHover={{ y: -3, boxShadow: '8px 8px 0 rgba(15,23,42,0.15)' }}
                  whileTap={{ scale: 0.97 }}
                  style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10, background: '#0f172a', color: '#fff', padding: '16px 0', borderRadius: 16, fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 15, textDecoration: 'none', border: '2px solid #0f172a', boxShadow: '6px 6px 0 rgba(15,23,42,0.1)', transition: 'box-shadow 0.2s' }}
                >
                  <Smartphone size={18} /> Open Mobile App
                </motion.a>
                <button
                  onClick={() => setShowAppModal(false)}
                  style={{ background: 'transparent', border: 'none', fontFamily: 'var(--font-body)', fontWeight: 800, fontSize: 14, color: '#94a3b8', padding: '12px 0', cursor: 'pointer' }}
                >
                  Maybe Later
                </button>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </div>
  );
};

export default Profile;