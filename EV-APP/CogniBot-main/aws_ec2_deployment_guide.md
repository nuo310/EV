# AWS EC2 Deployment Guide (IP Address Only — No Domain Required)

This guide walks you through deploying your OCPP backend to an AWS EC2 virtual machine using **only a public IP address**. No domain name or SSL certificate is required for initial setup.

> **IMPORTANT**: Without a domain, the charger will connect using `ws://` (plain WebSocket) instead of `wss://` (secure). This is perfectly fine for development and testing. SSL can be added later when you purchase a domain.

---

## Phase 1: Create an AWS EC2 Instance

### Step 1: Log in to AWS Console
1. Go to [https://aws.amazon.com/console/](https://aws.amazon.com/console/) and sign in.
2. In the top search bar, type **EC2** and click on it.

### Step 2: Launch a New Instance
1. Click the orange **"Launch instance"** button.
2. Fill in the following configuration:

| Setting | Value |
|---|---|
| **Name** | `ocpp-backend-server` |
| **OS Image (AMI)** | Ubuntu Server 22.04 LTS (Free tier eligible) |
| **Instance type** | `t3.micro` (Free tier) or `t3.small` (if you need more power) |
| **Key pair** | Click **"Create new key pair"** → Name it `ocpp-key` → Select `.pem` format → Click **Create**. This will download a `.pem` file to your computer. **Keep this file safe — you need it to SSH into the server.** |

### Step 3: Configure Security Group (Firewall Rules)
Under **Network settings**, click **Edit** and add the following **Inbound rules**:

| Type | Port Range | Source | Purpose |
|---|---|---|---|
| SSH | 22 | My IP (or 0.0.0.0/0) | Remote terminal access |
| HTTP | 80 | 0.0.0.0/0 | Health check / web access |
| Custom TCP | 9221 | 0.0.0.0/0 | Direct backend API access |
| Custom TCP | 8080 | 0.0.0.0/0 | WebSocket charger connections |

> **NOTE**: Port `9221` exposes your backend REST API directly. Port `8080` is for charger WebSocket connections if you later want to match the ZynkaTech format. With Nginx (covered below), you can consolidate everything onto port `80`.

### Step 4: Configure Storage
Set the root volume to **20 GB** (gp3). The default 8 GB can fill up quickly with logs and node_modules.

### Step 5: Launch
Click **"Launch instance"**. Wait 1-2 minutes for it to spin up.

---

## Phase 2: Allocate a Static IP (Elastic IP)

By default, your EC2 instance gets a new IP every time it reboots. To fix this:

1. In the EC2 sidebar, click **Elastic IPs** (under Network & Security).
2. Click **"Allocate Elastic IP address"** → Click **Allocate**.
3. Select the new Elastic IP → Click **Actions** → **Associate Elastic IP address**.
4. Choose your `ocpp-backend-server` instance → Click **Associate**.

**Write down your Elastic IP address** (e.g., `3.110.45.123`). This is your permanent server address.

---

## Phase 3: Connect to Your Server via SSH

### From Windows (PowerShell)
1. Open PowerShell.
2. Navigate to where your `.pem` key file was downloaded:
   ```powershell
   cd ~/Downloads
   ```
3. Connect to your server:
   ```powershell
   ssh -i "ocpp-key.pem" ubuntu@YOUR_ELASTIC_IP
   ```
   Replace `YOUR_ELASTIC_IP` with your actual Elastic IP (e.g., `3.110.45.123`).

4. If prompted `Are you sure you want to continue connecting?`, type `yes`.

You are now inside your Ubuntu server terminal!

---

## Phase 4: Install Required Software on the Server

Run these commands one by one inside your SSH session:

### 1. Update System Packages
```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Install Node.js 18+
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

Verify the installation:
```bash
node -v   # Should print v18.x.x
npm -v    # Should print 9.x.x or higher
```

### 3. Install Git
```bash
sudo apt install -y git
```

### 4. Install PM2 (Process Manager)
```bash
sudo npm install -g pm2
```

### 5. Install Nginx (Reverse Proxy)
```bash
sudo apt install -y nginx
```

---

## Phase 5: Deploy Your OCPP Backend Code

### 1. Clone Your Repository
```bash
cd ~
git clone https://github.com/nuo310/EV.git
cd EV/EV-APP/CogniBot-main/ocpp-backend
```

### 2. Install Node.js Dependencies
```bash
npm install
```

### 3. Upload Your Firebase Service Account Key
From your **local Windows machine** (open a new PowerShell window), upload the key file:
```powershell
scp -i "~/Downloads/ocpp-key.pem" "d:\Flutter Projects\EV-APP\EV-APP\CogniBot-main\ocpp-backend\ev-app-firebase-service.json" ubuntu@YOUR_ELASTIC_IP:~/EV/EV-APP/CogniBot-main/ocpp-backend/
```

### 4. Create the Production `.env` File
Back in your SSH session:
```bash
cd ~/EV/EV-APP/CogniBot-main/ocpp-backend
nano .env
```
Type the following content:
```
PORT=9221
```
Save and exit: Press `Ctrl + X`, then `Y`, then `Enter`.

### 5. Test Run the Server
```bash
node server.js
```
You should see:
```
🔥 Successfully connected to Firebase Admin SDK for Project: ev-app-4b0f9
Express initialized successfully
Server starting on port 9221
🚀 Server running on Railway port 9221
```
Press `Ctrl + C` to stop it (we will use PM2 next).

---

## Phase 6: Run Backend with PM2 (Keeps It Running Forever)

### 1. Start the Backend with PM2
```bash
cd ~/EV/EV-APP/CogniBot-main/ocpp-backend
pm2 start server.js --name ocpp-backend
```

### 2. Configure PM2 to Auto-Start on Reboot
```bash
pm2 startup
```
It will print a command starting with `sudo env PATH=...`. **Copy and paste that entire command** and run it.

Then save the current process list:
```bash
pm2 save
```

### 3. Useful PM2 Commands
```bash
pm2 status          # Check if the backend is running
pm2 logs            # View live server logs
pm2 restart all     # Restart after code changes
pm2 stop all        # Stop the server
```

---

## Phase 7: Configure Nginx Reverse Proxy

Nginx acts as a gatekeeper, forwarding both HTTP API requests and WebSocket charger connections to your Node.js backend running on port `9221`.

### 1. Create the Nginx Configuration
```bash
sudo nano /etc/nginx/sites-available/ocpp
```

Paste the following content (replace nothing — this works with just the IP):
```nginx
server {
    listen 80;
    server_name _;

    # Health check & REST API forwarding
    location / {
        proxy_pass http://127.0.0.1:9221;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # OCPP WebSocket connections from chargers
    location /ws/ {
        proxy_pass http://127.0.0.1:9221;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 86400s;   # 24 hours — prevents idle disconnects
        proxy_send_timeout 86400s;
    }

    # OCPP connections via /ocpp/ path
    location /ocpp/ {
        proxy_pass http://127.0.0.1:9221;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
```

Save and exit: `Ctrl + X` → `Y` → `Enter`.

### 2. Enable the Configuration
```bash
# Remove the default Nginx page
sudo rm /etc/nginx/sites-enabled/default

# Enable your OCPP config
sudo ln -s /etc/nginx/sites-available/ocpp /etc/nginx/sites-enabled/

# Test for syntax errors
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

---

## Phase 8: Verify Deployment

### 1. Test the Health Check (From Your Browser)
Open your browser and go to:
```
http://YOUR_ELASTIC_IP/
```
You should see: **`Railway backend alive 🚀`**

### 2. Test the Station Status API (From Postman)
* **Method**: `GET`
* **URL**: `http://YOUR_ELASTIC_IP/stations/mgch001/status`
* **Expected Response**:
  ```json
  {
    "stationId": "mgch001",
    "connected": false,
    "status": "Unavailable",
    "telemetry": null
  }
  ```

### 3. Test WebSocket Charger Connection
Update your local simulator to point to AWS:
```javascript
// In simulator.js, change:
const BACKEND_URL = "ws://YOUR_ELASTIC_IP/ws/1.6/mgch001";
```
Run the simulator locally. The PM2 logs on your server (`pm2 logs`) should show:
```
🔌 ChargePoint Connected: mgch001
```

---

## Phase 9: Configure the Physical ZynkaTech Charger

Once everything is verified with the simulator, configure the physical charger:

1. Access the charger's local Wi-Fi hotspot and open `http://192.168.4.1/chargingpoint`.
2. In the **URL section**, enter:
   ```
   ws://YOUR_ELASTIC_IP/ws/1.6/mgch001
   ```
3. Save and reboot the charger.
4. Monitor your server logs:
   ```bash
   pm2 logs
   ```
   You should see: `🔌 ChargePoint Connected: mgch001`

---

## Quick Reference Card

| What | Value |
|---|---|
| **Server Health Check** | `http://YOUR_ELASTIC_IP/` |
| **Station Status API** | `http://YOUR_ELASTIC_IP/stations/{stationId}/status` |
| **Remote Start API** | `POST http://YOUR_ELASTIC_IP/remote-start` |
| **Remote Stop API** | `POST http://YOUR_ELASTIC_IP/remote-stop` |
| **Charger WebSocket URL** | `ws://YOUR_ELASTIC_IP/ws/1.6/mgch001` |
| **SSH Access** | `ssh -i "ocpp-key.pem" ubuntu@YOUR_ELASTIC_IP` |
| **View Server Logs** | `pm2 logs` (inside SSH) |
| **Restart Server** | `pm2 restart ocpp-backend` (inside SSH) |

---

## Adding SSL Later (When You Get a Domain)

When you eventually purchase a domain name, you can upgrade to secure WebSockets (`wss://`) by:
1. Pointing your domain's A record to your Elastic IP.
2. Running Certbot to auto-configure SSL:
   ```bash
   sudo apt install -y certbot python3-certbot-nginx
   sudo certbot --nginx -d ocpp.yourdomain.com
   ```
3. Updating the charger URL from `ws://` to `wss://`.

> **TIP**: Until you add SSL, everything works perfectly fine over `ws://` (plain WebSocket). The only difference is that the data is not encrypted in transit. For development, testing, and internal deployments, this is completely acceptable.
