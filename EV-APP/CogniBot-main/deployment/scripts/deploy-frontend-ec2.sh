#!/bin/bash

# Exit on error
set -e

echo "============================================="
echo "Deploying React Frontend via Nginx on EC2"
echo "============================================="

# 1. Update and install Nginx
echo "--> Installing Nginx web server..."
sudo apt-get update -y
sudo apt-get install -y nginx

# 2. Build the client application
echo "--> Going to client directory..."
cd /home/ubuntu/EV/EV-APP/CogniBot-main/client

echo "--> Installing client dependencies..."
npm install

echo "--> Building production assets..."
# This uses the local .env file we configured with the new IP 51.20.41.4
npm run build

# 3. Copy build files to Nginx web root directory
echo "--> Copying build files to /var/www/client..."
sudo mkdir -p /var/www/client
sudo rm -rf /var/www/client/*
sudo cp -r /home/ubuntu/EV/EV-APP/CogniBot-main/client/dist/* /var/www/client/

echo "--> Setting permissions..."
sudo chown -R www-data:www-data /var/www/client
sudo chmod -R 755 /var/www/client

# 4. Write Nginx Configuration
echo "--> Configuring Nginx..."
cat << 'EOF' | sudo tee /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/client;
    index index.html;

    server_name _;

    # React router support (always redirect to index.html for client side routing)
    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF

# 5. Restart Nginx
echo "--> Restarting Nginx to apply changes..."
sudo systemctl restart nginx

echo "============================================="
echo "Frontend Deployment Completed successfully! 🎉"
echo "============================================="
echo "Next steps:"
echo "1. Ensure Port 80 (HTTP) is open in your AWS Security Group."
echo "2. Open http://51.20.41.4 in your browser to view your website!"
echo "============================================="
