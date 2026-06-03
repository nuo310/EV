# Firebase Integration & ZynkaTech Charger Onboarding Documentation

This document serves as the guide for the Firebase database configurations, the ZynkaTech EV charger integration details, and the steps for production deployment to AWS.

---

## 1. Firebase Integration Configurations

The application has been shifted from a local mock environment directly onto the live production Firebase infrastructure. The setup is configured for both client-side and server-side operations.

### A. Client-Side configuration (React Web Client)
*   **Target Config File**: [firebaseConfig.js](file:///d:/Flutter%20Projects/EV-APP/EV-APP/CogniBot-main/client/src/lib/firebaseConfig.js)
*   **Properties Configured**:
    ```javascript
    export const firebaseConfig = {
      apiKey: "AIzaSyChKMPYtBaSZJyABqUKT-Qma0JfgObPuCc",
      authDomain: "ev-app-4b0f9.firebaseapp.com",
      projectId: "ev-app-4b0f9",
      storageBucket: "ev-app-4b0f9.firebasestorage.app",
      messagingSenderId: "40038334977",
      appId: "1:40038334977:web:cc2e615924153a8283b600",
      measurementId: "G-EZ82E0K4YG"
    };
    ```

### B. Server-Side Configuration (OCPP Node.js Backend)
*   **Target Config File**: [firebase.js](file:///d:/Flutter%20Projects/EV-APP/EV-APP/CogniBot-main/ocpp-backend/firebase.js)
*   **Mechanic**: Replaced the local fallback mock database code. The backend now loads the service account key dynamically from [ev-app-firebase-service.json](file:///d:/Flutter%20Projects/EV-APP/EV-APP/CogniBot-main/ocpp-backend/ev-app-firebase-service.json) located in the backend folder root.
*   **Execution Code**:
    ```javascript
    const admin = require("firebase-admin");
    const path = require("path");

    const serviceAccountPath = path.join(__dirname, "ev-app-firebase-service.json");
    const serviceAccount = require(serviceAccountPath);

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });

    const db = admin.firestore();
    console.log("🔥 Successfully connected to Firebase Admin SDK for Project: " + serviceAccount.project_id);
    module.exports = db;
    ```

---

## 2. ZynkaTech Charger Profile & OCPP Lifecyle

The ZynkaTech EV charger acts as a standard **OCPP 1.6 JSON Client** connecting to a central backend using WebSockets.

### Connection Architecture
```text
[ ZynkaTech EV Charger ] 
       │ (WebSocket TCP Connection)
       ▼
[ ws://websoc.zynkatech.com:8080/ws/1.6/mgch001 ]
```
*   **`websoc.zynkatech.com:8080`**: The host address.
*   **`/ws/1.6/`**: The route path enforcing the OCPP 1.6 protocol version.
*   **`mgch001`**: The unique identifier (ChargePoint ID) assigned to the device.

### OCPP Message Lifecycle
When the charger connects, it goes through the following communication cycle:

```mermaid
sequenceDiagram
    participant Charger as ZynkaTech Charger (Client)
    participant Server as Custom AWS Backend (Server)

    Note over Charger, Server: Connection Establishment
    Charger->>Server: Connects via WebSocket (ws/wss)
    Server-->>Charger: Socket Connected & Registered

    Note over Charger, Server: Boot & Idle Diagnostics
    Charger->>Server: BootNotification [2, UniqueId, "BootNotification", { model, vendor }]
    Server-->>Charger: CallResult [3, UniqueId, { status: "Accepted", interval: 60 }]
    Charger->>Server: StatusNotification [2, UniqueId, { connectorId: 1, status: "Available" }]
    Server-->>Charger: CallResult [3, UniqueId, {}]
    
    Note over Charger, Server: Scheduled Heartbeats
    loop Every 60 Seconds
        Charger->>Server: Heartbeat [2, UniqueId, "Heartbeat", {}]
        Server-->>Charger: CallResult [3, UniqueId, { currentTime }]
    end
```

---

## 3. Step-by-Step Charger Configuration Guide

To transition the charger from the ZynkaTech backend to your custom cloud backend, perform the following steps:

1.  **Boot the Charger**: Turn on the ZynkaTech EV charger. Wait for its network status lights to stabilize.
2.  **Connect to Local Hotspot**: Locate the Wi-Fi network broadcasted by the charger (usually named using the serial number or `Zynka-XXXX`). Connect your laptop or mobile phone to this SSID.
3.  **Access the Admin Interface**: Open your browser and navigate to the default gateway IP address (typically `http://192.168.4.1` or `http://192.168.0.1` as detailed in the charger manual).
4.  **Update OCPP Configuration URL**:
    *   Navigate to **Network Config** or **OCPP Settings**.
    *   Change the target URL field from `ws://websoc.zynkatech.com:8080/ws/1.6/mgch001` to:
        ```text
        wss://ocpp.mydomain.com/ws/1.6/mgch001
        ```
5.  **Configure Local Network Connection**: Under Wi-Fi Configuration, verify that the charger's local SSID and password credentials match the on-site router so it can access the internet.
6.  **Save and Restart**: Save the changes and select **Reboot**. The charger will reboot, connect to the local Wi-Fi, and initiate an encrypted secure handshake with your AWS endpoint.

---

## 4. Production Deployment to AWS

To deploy this backend architecture to a production-ready AWS instance with SSL validation, follow the steps below:

### Phase 1: Provisioning the Virtual Server
1.  Launch an **AWS EC2 Instance** (Ubuntu 22.04 LTS, `t3.micro` or `t3.small` instance type is recommended).
2.  Assign an **Elastic IP** to bind a static public IP to the instance.
3.  Modify the instance **Security Group** to allow the following inbound traffic:
    *   Port `80` (HTTP) — Used for domain verification.
    *   Port `443` (HTTPS/WSS) — The entry port for client APIs and charger connections.
    *   Port `22` (SSH) — For remote server maintenance.

### Phase 2: Deploying Node.js and the OCPP Backend
1.  SSH into your Ubuntu server and install node dependencies:
    ```bash
    sudo apt update
    sudo apt install -y nodejs npm git
    ```
2.  Clone the repository and install project packages:
    ```bash
    git clone <your-repository-url>
    cd CogniBot-main/ocpp-backend
    npm install
    ```
3.  Copy the `ev-app-firebase-service.json` and a production `.env` (configured with `PORT=9221`) into the backend directory.
4.  Install **PM2** to run the backend as a background process:
    ```bash
    sudo npm install -g pm2
    pm2 start server.js --name ocpp-backend
    pm2 startup
    pm2 save
    ```

### Phase 3: Setup Nginx Reverse Proxy with SSL (WSS Support)
Nginx is used to forward requests to the local Node.js process and handle SSL handshakes.

1.  **Install Nginx**:
    ```bash
    sudo apt install -y nginx
    ```
2.  **Configure Server Blocks**: Create a configuration file `/etc/nginx/sites-available/ocpp`:
    ```nginx
    server {
        listen 80;
        server_name ocpp.mydomain.com;

        # Standard REST API forwarding
        location / {
            proxy_pass http://127.0.0.1:9221;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        # Secure OCPP WebSocket (WSS) forwarding
        location /ws/ {
            proxy_pass http://127.0.0.1:9221;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_read_timeout 3600s; # Long timeout to prevent idle connection drops
        }
    }
    ```
3.  **Enable Configuration**:
    ```bash
    sudo ln -s /etc/nginx/sites-available/ocpp /etc/nginx/sites-enabled/
    sudo nginx -t
    sudo systemctl restart nginx
    ```
4.  **Obtain Let's Encrypt SSL Certificate**:
    ```bash
    Certbot will automatically verify ownership of your domain, download the certificates, and configure Nginx to route all traffic securely via `HTTPS` / `WSS`.

---

## 5. Programmatic Charging Session Initiation (Code Integration)

To trigger the physical charger from your codebase (bypassing manual dashboard setups), the system relies on a unified **WebSocket transaction tunnel**. The physical charger does not receive incoming HTTP requests. Instead, it maintains a continuous, open WebSocket connection to your backend, waiting to receive OCPP command strings.

### A. Sequence of Execution

```mermaid
sequenceDiagram
    participant Client as React Client (Frontend)
    participant Server as Express Server (Backend)
    participant Charger as ZynkaTech Charger (Physical)

    Client->>Server: HTTP POST /remote-start { stationId: "mgch001" }
    Note over Server: 1. Looks up chargers["mgch001"] socket<br/>2. Generates Unique message UUID
    Server->>Charger: WebSocket Send: [2, "UUID", "RemoteStartTransaction", { connectorId: 1, idTag: "WEB_APP" }]
    Note over Charger: 3. Receives OCPP payload<br/>4. Fires physical relay (charging click)<br/>5. Begins drawing electricity
    Charger-->>Server: WebSocket Reply: [3, "UUID", { status: "Accepted" }]
    Server-->>Client: HTTP Response: { status: "Accepted" }
```

### B. Backend Implementation (Express REST Endpoint)
Your backend (`ocpp-backend/server.js`) maps incoming HTTP calls onto the corresponding WebSocket client channel using an in-memory socket manager:

```javascript
// 1. Maintain connected clients map
const chargers = {};

wss.on("connection", (ws, request) => {
  // Parse chargePointId from URL path (e.g. "/ws/1.6/mgch001" -> "mgch001")
  const chargePointId = request.url.split("/").pop();
  chargers[chargePointId] = ws; // Store reference
  
  ws.on("close", () => {
    delete chargers[chargePointId]; // Clean up on disconnect
  });
});

// 2. Expose the trigger endpoint
app.post("/remote-start", async (req, res) => {
  const { stationId } = req.body; // e.g. "mgch001"

  if (!stationId) {
    return res.status(400).json({ error: "stationId is required" });
  }

  try {
    const ws = chargers[stationId];
    if (!ws || ws.readyState !== ws.OPEN) {
      throw new Error(`Charger offline or not connected: ${stationId}`);
    }

    // Call the OCPP helper to send a RemoteStartTransaction call
    const uniqueId = uuidv4();
    const callMessage = [
      2,              // MessageTypeId (2 = Call)
      uniqueId,       // Message tracking UUID
      "RemoteStartTransaction",
      { connectorId: 1, idTag: "WEB_APP" }
    ];

    ws.send(JSON.stringify(callMessage));
    console.log(`[OCPP] Sent RemoteStartTransaction to ${stationId}`);
    
    res.json({ status: "Accepted", messageId: uniqueId });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

### C. Client Integration (React Frontend)
In your frontend React codebase (`client/src/services/ocppService.js`), make a standard HTTP request to target the remote-start endpoint:

```javascript
async sendRemoteStart(stationId, payload = {}) {
  const response = await fetch("/api/remote-start", {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      stationId,
      connectorId: payload.connectorId || 1,
      idTag: payload.idTag || "WEB_APP"
    })
  });

  const body = await response.json();
  if (!response.ok) {
    throw new Error(body.error || `Remote start failed for ${stationId}`);
  }
  return body;
}
```

### D. Testing the Loop (Postman)
1. Verify the physical charger is connected to your backend (terminal prints `🔌 ChargePoint Connected: mgch001`).
2. Open Postman and send a **`POST`** request:
   * **URL**: `http://localhost:9221/remote-start`
   * **Headers**: `Content-Type: application/json`
   * **Body (raw JSON)**:
     ```json
     {
       "stationId": "mgch001"
     }
     ```
3. Click **Send**. You will see `{ "status": "Accepted" }` returned in Postman, and the physical relay on the charger will activate immediately.

