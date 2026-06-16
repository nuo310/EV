import { useState, useEffect, useRef, useCallback } from 'react';

/**
 * useAdminSocket — Custom React hook for real-time admin telemetry.
 *
 * Connects to the backend /admin-telemetry WebSocket endpoint
 * and provides live charger status, event logs, and connection state.
 */
export default function useAdminSocket(backendBaseUrl) {
  const [connected, setConnected] = useState(false);
  const [liveChargers, setLiveChargers] = useState([]);
  const [logs, setLogs] = useState([]);
  const wsRef = useRef(null);
  const reconnectTimer = useRef(null);
  const MAX_LOGS = 200;

  const getWsUrl = useCallback(() => {
    // Derive WebSocket URL from the REST base URL
    let base = backendBaseUrl || '';
    if (!base) {
      // Fallback: same host, current protocol
      const proto = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
      base = `${proto}//${window.location.host}`;
    } else {
      base = base.replace(/^http/, 'ws');
    }
    return `${base.replace(/\/+$/, '')}/admin-telemetry`;
  }, [backendBaseUrl]);

  const addLog = useCallback((entry) => {
    setLogs(prev => {
      const next = [{ ...entry, id: Date.now() + Math.random(), receivedAt: new Date().toISOString() }, ...prev];
      return next.length > MAX_LOGS ? next.slice(0, MAX_LOGS) : next;
    });
  }, []);

  const connectWs = useCallback(() => {
    if (wsRef.current && wsRef.current.readyState <= 1) return;

    const url = getWsUrl();
    console.log('[AdminSocket] Connecting to', url);

    try {
      const ws = new WebSocket(url);
      wsRef.current = ws;

      ws.onopen = () => {
        console.log('[AdminSocket] Connected');
        setConnected(true);
        addLog({ type: 'system', message: 'Connected to admin telemetry' });
      };

      ws.onmessage = (event) => {
        try {
          const msg = JSON.parse(event.data);

          switch (msg.type) {
            case 'initial_snapshot':
              setLiveChargers(msg.data?.chargers || []);
              addLog({ type: 'system', message: `Received snapshot: ${msg.data?.count || 0} chargers connected` });
              break;

            case 'charger_connected':
              setLiveChargers(prev => {
                const exists = prev.find(c => c.id === msg.data.stationId);
                if (exists) {
                  return prev.map(c => c.id === msg.data.stationId
                    ? { ...c, connected: true, status: 'Available', readyState: 1 }
                    : c);
                }
                return [...prev, {
                  id: msg.data.stationId,
                  connected: true,
                  status: 'Available',
                  readyState: 1,
                  websocketUrl: msg.data.websocketUrl,
                  latitude: msg.data.latitude,
                  longitude: msg.data.longitude,
                  telemetry: null,
                }];
              });
              addLog({ type: 'connect', stationId: msg.data.stationId, message: `Charger ${msg.data.stationId} connected` });
              break;

            case 'charger_disconnected':
              setLiveChargers(prev =>
                prev.map(c => c.id === msg.data.stationId
                  ? { ...c, connected: false, status: 'Unavailable', readyState: 3 }
                  : c)
              );
              addLog({ type: 'disconnect', stationId: msg.data.stationId, message: `Charger ${msg.data.stationId} disconnected` });
              break;

            case 'status_notification':
              setLiveChargers(prev =>
                prev.map(c => c.id === msg.data.stationId
                  ? { ...c, status: msg.data.status, telemetry: { ...c.telemetry, lastStatusNotification: { status: msg.data.status, at: msg.data.at } } }
                  : c)
              );
              addLog({ type: 'status', stationId: msg.data.stationId, message: `Status: ${msg.data.status}`, data: msg.data });
              break;

            case 'heartbeat':
              setLiveChargers(prev =>
                prev.map(c => c.id === msg.data.stationId
                  ? { ...c, telemetry: { ...c.telemetry, lastHeartbeatAt: msg.data.at, lastSeenAt: msg.data.at } }
                  : c)
              );
              addLog({ type: 'heartbeat', stationId: msg.data.stationId, message: `Heartbeat from ${msg.data.stationId}` });
              break;

            case 'meter_values':
              setLiveChargers(prev =>
                prev.map(c => c.id === msg.data.stationId
                  ? { ...c, telemetry: { ...c.telemetry, lastMeterValues: msg.data.meterValues } }
                  : c)
              );
              addLog({ type: 'meter', stationId: msg.data.stationId, message: `Meter values from ${msg.data.stationId}`, data: msg.data });
              break;

            default:
              addLog({ type: 'unknown', message: `Unknown event: ${msg.type}`, data: msg });
          }
        } catch (e) {
          console.error('[AdminSocket] Parse error:', e);
        }
      };

      ws.onclose = () => {
        console.log('[AdminSocket] Disconnected, reconnecting in 3s...');
        setConnected(false);
        addLog({ type: 'system', message: 'Disconnected — reconnecting...' });
        reconnectTimer.current = setTimeout(connectWs, 3000);
      };

      ws.onerror = (err) => {
        console.error('[AdminSocket] Error:', err);
        ws.close();
      };
    } catch (e) {
      console.error('[AdminSocket] Connection failed:', e);
      reconnectTimer.current = setTimeout(connectWs, 3000);
    }
  }, [getWsUrl, addLog]);

  useEffect(() => {
    connectWs();
    return () => {
      clearTimeout(reconnectTimer.current);
      if (wsRef.current) {
        wsRef.current.onclose = null; // Prevent reconnect on unmount
        wsRef.current.close();
      }
    };
  }, [connectWs]);

  const clearLogs = useCallback(() => setLogs([]), []);

  return { connected, liveChargers, logs, clearLogs };
}
