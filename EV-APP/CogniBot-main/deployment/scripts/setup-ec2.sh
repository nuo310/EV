#!/bin/bash

# Exit on error
set -e

echo "============================================="
echo "Initializing EC2 Environment for OCPP Backend"
echo "============================================="

# 1. Update OS package lists
echo "--> Updating system package index..."
sudo apt-get update -y

# 2. Install essential dependencies
echo "--> Installing curl, git, and build tools..."
sudo apt-get install -y curl git build-essential

# 3. Install Node.js v20.x (LTS) via NodeSource
echo "--> Adding NodeSource repository for Node.js v20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

echo "--> Installing Node.js..."
sudo apt-get install -y nodejs

# Verify installation
NODE_VER=$(node -v)
NPM_VER=$(npm -v)
echo "Installed Node.js version: $NODE_VER"
echo "Installed npm version: $NPM_VER"

# 4. Install PM2 globally for running Node.js apps persistently
echo "--> Installing PM2 globally..."
sudo npm install -g pm2

# Verify installation
PM2_VER=$(pm2 -v)
echo "Installed PM2 version: $PM2_VER"

# 5. Configure PM2 to run on startup
echo "--> Configuring PM2 startup scripts..."
# This generates the startup command for Ubuntu systemd
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu

echo "============================================="
echo "EC2 Setup Completed Successfully! 🎉"
echo "============================================="
echo "Next steps:"
echo "1. Clone your project code or upload the 'ocpp-backend' folder to this server."
echo "2. Inside 'ocpp-backend', copy your Firebase service key file: 'ev-app-firebase-service.json'"
echo "3. Create a '.env' file with your CCAvenue keys, PORT=9221, and new backend address URL."
echo "4. Run: npm install"
echo "5. Run: pm2 start server.js --name ocpp-backend"
echo "6. Run: pm2 save (to persist the app on reboot)"
echo "============================================="
