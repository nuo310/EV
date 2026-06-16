# 🚀 Complete EC2 Deployment Guide: Backend & Frontend

This document provides a comprehensive, step-by-step walkthrough to redeploy the **CogniBot EV Application** (both Node.js OCPP backend and React frontend) to a fresh AWS EC2 instance.

---

## 🗺️ Deployment Architecture

```mermaid
graph TD
    Client[Web Browser / Mobile App] -->|HTTP Port 80| Nginx[Nginx Reverse Proxy]
    Nginx -->|Serves Static Files| Frontend[React Client dist/]
    Client -->|HTTP/WS Port 9221| Backend[Node.js OCPP Backend]
    Backend -->|Manages| PM2[PM2 Process Manager]
    Backend -->|Auth & Database| Firebase[Firebase Admin SDK]
    Backend -->|Payments| CCAvenue[CCAvenue API]
```

---

## 🛠️ Step 1: Provision your EC2 Instance

1. **Launch a new Instance** in your AWS Console.
2. **OS Image (AMI)**: Choose **Ubuntu 22.04 LTS** or **Ubuntu 24.04 LTS** (64-bit x86).
3. **Instance Type**: `t2.micro` or `t3.micro` (eligible for Free Tier) is sufficient.
4. **Key Pair**: Create or select an existing key pair (e.g., `ocpp-key.pem`). Download and save it securely.
5. **Network / Security Group**:
   Create a security group with the following inbound rules:

| Protocol | Port Range | Source | Purpose |
| :--- | :--- | :--- | :--- |
| **SSH** | `22` | `0.0.0.0/0` (or your IP) | CLI administration and deployment |
| **HTTP** | `80` | `0.0.0.0/0` | Accessing the React Frontend |
| **OCPP/API** | `9221` | `0.0.0.0/0` | Express Backend and WebSocket Chargers |

---

## 🔑 Step 2: Connect via SSH and Clone Code

### 1. Fix SSH Key Permissions (Local Machine)

Before connecting, SSH requires strict file permissions on your private key:

* **On Windows (PowerShell):**
  ```powershell
  # Disable inheritance and grant read access only to your user
  icacls "C:\path\to\ocpp-key.pem" /inheritance:r /grant:r "$($env:USERNAME):R"
  ```
* **On Linux / macOS:**
  ```bash
  chmod 400 ocpp-key.pem
  ```

### 2. Connect to EC2
Run the following command (replace with your key path and EC2 Public IP):
```bash
ssh -i "path/to/ocpp-key.pem" ubuntu@<YOUR_EC2_PUBLIC_IP>
```

### 3. Clone the Repository
Inside the EC2 terminal, create the project directory and clone the code:
```bash
# Create directory structure
mkdir -p /home/ubuntu/EV
cd /home/ubuntu/EV

# Clone repository (make sure to replace with your repository URL)
git clone <YOUR_GIT_REPOSITORY_URL> .
```

---

## ⚙️ Step 3: Run the Environment Setup Script

We have provided a automated setup script that installs:
- Node.js v20.x (LTS)
- Git & Build tools
- PM2 (Process Manager)
- Nginx (Web Server)

Make the script executable and run it:
```bash
cd /home/ubuntu/EV/EV-APP/CogniBot-main/deployment/scripts
chmod +x setup-ec2.sh
./setup-ec2.sh
```

---

## 📦 Step 4: Configure & Run the Backend

Navigate to the backend directory and set up environment variables:

```bash
cd /home/ubuntu/EV/EV-APP/CogniBot-main/ocpp-backend
```

### 1. Create your Environment File (`.env`)
Create a `.env` file in the `ocpp-backend` folder:
```bash
nano .env
```
Copy and paste the configuration below, substituting your values:
```env
PORT=9221

# CCAvenue Payment Gateway Config
CCAVENUE_MERCHANT_ID=4447763
CCAVENUE_ACCESS_CODE=ATJV92NE88CE38VJEC
CCAVENUE_WORKING_KEY=6920AF15658E966037F353849C0A60E3
CCAVENUE_API_URL=https://test.ccavenue.com/transaction/transaction.do?command=initiateTransaction

# CCAvenue redirect URLs (Use your EC2 Public IP or Custom Domain)
CCAVENUE_REDIRECT_URL=http://<YOUR_EC2_PUBLIC_IP>:9221/api/payment/response
CCAVENUE_CANCEL_URL=http://<YOUR_EC2_PUBLIC_IP>:9221/api/payment/response

# Frontend URL (For redirecting user after payment)
FRONTEND_URL=http://<YOUR_EC2_PUBLIC_IP>/
```
*(Press `Ctrl+O` then `Enter` to save, and `Ctrl+X` to exit nano)*

### 2. Copy the Firebase Admin SDK Key
The backend uses Firebase Admin SDK. You must put the service account JSON key file at the following path:
`/home/ubuntu/EV/EV-APP/CogniBot-main/ocpp-backend/ev-app-firebase-service.json`

If you don't have it on GitHub (recommended to not commit credentials), copy the file contents from your local machine and write it on EC2:
```bash
nano ev-app-firebase-service.json
```
*(Paste your Firebase Service Account JSON payload, save and exit)*

### 3. Install Dependencies and Start the Backend with PM2
```bash
# Install dependencies
npm install

# Start the application using PM2
pm2 start server.js --name ocpp-backend

# Ensure PM2 saves and automatically restarts on system reboot
pm2 save
```

To verify the backend is running correctly:
```bash
pm2 status
pm2 logs ocpp-backend
```

---

## 🖥️ Step 5: Configure & Deploy the Frontend

### 1. Configure Client Environment (`.env`)
On your **local machine**, edit the client environment file at `EV-APP/CogniBot-main/client/.env`. Update the backend address to point to your new EC2 Public IP:

```env
# Point to your new EC2 Instance IP and Backend Port
VITE_OCPP_REMOTE_START_BASE_URL=http://<YOUR_EC2_PUBLIC_IP>:9221

# Firebase credentials
VITE_FIREBASE_API_KEY="AIzaSyD-AsfBSVdeEOcIWwUN4GVWphJ7yLof6nU"
VITE_FIREBASE_AUTH_DOMAIN="ev-charging-app-2026.firebaseapp.com"

# API keys
VITE_OCM_API_KEY="6e78df7e-e6d3-44ee-b911-4b2c43fb8627"
VITE_GOOGLE_MAPS_API_KEY="AIzaSyB13nYkdqc8OITqwB5F1AziHKKT_d37TVw"
```

Save the file, commit the change, and push it to your GitHub repository:
```bash
git add client/.env
git commit -m "Update frontend backend URL to new EC2 IP"
git push origin main
```

### 2. Update code and build on EC2
Go back to your SSH terminal on your EC2 instance:
```bash
# Pull the latest client/.env file you just pushed
cd /home/ubuntu/EV
git pull origin main

# Execute frontend deployment script
cd /home/ubuntu/EV/EV-APP/CogniBot-main/deployment/scripts
chmod +x deploy-frontend-ec2.sh
./deploy-frontend-ec2.sh
```

This script will automatically:
1. Build the production React assets.
2. Copy them to `/var/www/client`.
3. Configure Nginx with correct routing logic.
4. Restart Nginx to serve the site on Port 80.

---

## 🔍 Step 6: Verify and Troubleshoot

### 1. Check Frontend Availability
Open your browser and navigate to `http://<YOUR_EC2_PUBLIC_IP>`. You should see the React application landing page loaded.

### 2. Verify Backend WebSocket & APIs
Verify that the server is listening on port `9221`:
```bash
sudo netstat -tulpn | grep 9221
# Or
curl http://localhost:9221/
```

### 3. Key Nginx & PM2 commands for maintenance

* **View live backend logs:**
  ```bash
  pm2 logs ocpp-backend
  ```
* **Restart the backend:**
  ```bash
  pm2 restart ocpp-backend
  ```
* **Check Nginx status & logs:**
  ```bash
  sudo systemctl status nginx
  sudo tail -f /var/log/nginx/error.log
  ```
