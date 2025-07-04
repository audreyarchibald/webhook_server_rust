#!/bin/bash

# Build script for cross-compiling to x86_64-unknown-linux-gnu

echo "Installing cross-compilation target..."
rustup target add x86_64-unknown-linux-gnu

echo "Building for x86_64-unknown-linux-gnu..."
cargo build --release --target x86_64-unknown-linux-gnu

echo "Build complete! Binary located at:"
echo "target/x86_64-unknown-linux-gnu/release/trading_webhook_server"

echo ""
echo "To deploy to EC2:"
echo "1. Copy the binary to your EC2 instance"
echo "2. Set environment variables:"
echo "   export ALPACA_API_KEY=your_api_key"
echo "   export ALPACA_SECRET_KEY=your_secret_key"
echo "   export PORT=3000"
echo "3. Run the server: ./trading_webhook_server"
