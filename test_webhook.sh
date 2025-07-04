#!/bin/bash

# Test script for the trading webhook server
# Usage: ./test_webhook.sh [server_url]

SERVER_URL=${1:-"http://localhost:3000"}

echo "Testing webhook endpoint at $SERVER_URL"

# Test health check
echo "1. Testing health check..."
curl -s "$SERVER_URL/health"
echo -e "\n"

# Test webhook with buy order
echo "2. Testing buy order webhook..."
curl -X POST "$SERVER_URL/webhook" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "buy",
    "ticker": "AAPL",
    "price": "150.25"
  }'
echo -e "\n"

# Test webhook with sell order
echo "3. Testing sell order webhook..."
curl -X POST "$SERVER_URL/webhook" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "sell",
    "ticker": "AAPL",
    "price": "149.75"
  }'
echo -e "\n"

# Test invalid action
echo "4. Testing invalid action..."
curl -X POST "$SERVER_URL/webhook" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "invalid",
    "ticker": "AAPL",
    "price": "150.00"
  }'
echo -e "\n"

echo "Test completed!"
