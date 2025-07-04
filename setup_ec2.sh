#!/bin/bash

# Setup script for EC2 deployment
echo "=== Trading Webhook Server EC2 Setup ==="

# Check if binary exists
if [ ! -f "/home/ubuntu/trading_webhook_server/trading_webhook_server" ]; then
    echo "Error: Binary not found! Please upload the binary first."
    exit 1
fi

echo "1. Setting up environment variables..."
read -p "Enter your Alpaca API Key: " ALPACA_API_KEY
read -s -p "Enter your Alpaca Secret Key: " ALPACA_SECRET_KEY
echo

# Update the service file with actual API keys
sudo sed -i "s/your_api_key_here/$ALPACA_API_KEY/" /home/ubuntu/trading-webhook.service
sudo sed -i "s/your_secret_key_here/$ALPACA_SECRET_KEY/" /home/ubuntu/trading-webhook.service

echo "2. Installing systemd service..."
sudo mv /home/ubuntu/trading-webhook.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable trading-webhook

echo "3. Starting the service..."
sudo systemctl start trading-webhook

echo "4. Checking service status..."
sudo systemctl status trading-webhook --no-pager

echo "5. Testing health endpoint..."
sleep 2
curl -s http://localhost:3000/health || echo "Service may still be starting..."

echo ""
echo "=== Setup Complete! ==="
echo "Your trading webhook server is now running on port 3000"
echo ""
echo "To test the webhook:"
echo "  ./test_webhook.sh http://$(curl -s http://checkip.amazonaws.com):3000"
echo ""
echo "To check logs:"
echo "  sudo journalctl -u trading-webhook -f"
echo ""
echo "To stop/start the service:"
echo "  sudo systemctl stop trading-webhook"
echo "  sudo systemctl start trading-webhook"
