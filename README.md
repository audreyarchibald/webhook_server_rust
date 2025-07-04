# Trading Webhook Server

A Rust-based API server that receives webhook requests from TradingView and places orders on Alpaca Markets.

## Features

- Receives POST requests from TradingView webhooks
- Automatically places orders on Alpaca Markets (paper trading by default)
- Cross-compiled for x86_64 Linux (Ubuntu EC2 compatible)
- Health check endpoint
- Comprehensive logging
- Systemd service support

## API Endpoints

### POST /webhook
Receives TradingView webhook requests with the following format:
```json
{
  "action": "buy|sell",
  "ticker": "AAPL",
  "price": "150.25"
}
```

### GET /health
Returns server health status.

## Prerequisites

- Rust 1.70+ (for building)
- Alpaca Markets account with API keys
- TradingView account with webhook capability

## Building

### Local Development
```bash
cargo run
```

### Cross-compilation for Ubuntu EC2
```bash
./build.sh
```

### Using Docker
```bash
docker build -t trading-webhook-server .
docker run -p 3000:3000 \
  -e ALPACA_API_KEY=your_api_key \
  -e ALPACA_SECRET_KEY=your_secret_key \
  trading-webhook-server
```

## Environment Variables

- `ALPACA_API_KEY`: Your Alpaca API key
- `ALPACA_SECRET_KEY`: Your Alpaca secret key
- `PORT`: Server port (default: 3000)
- `RUST_LOG`: Log level (default: info)

## Deployment to EC2

1. **Build the binary:**
   ```bash
   ./build.sh
   ```

2. **Copy files to EC2:**
   ```bash
   scp target/x86_64-unknown-linux-gnu/release/trading_webhook_server ubuntu@your-ec2-ip:/home/ubuntu/
   scp trading-webhook.service ubuntu@your-ec2-ip:/home/ubuntu/
   ```

3. **Set up on EC2:**
   ```bash
   # SSH into your EC2 instance
   ssh ubuntu@your-ec2-ip
   
   # Create directory
   mkdir -p /home/ubuntu/trading_webhook_server
   mv trading_webhook_server trading_webhook_server/
   
   # Make executable
   chmod +x trading_webhook_server/trading_webhook_server
   
   # Edit service file with your API keys
   nano trading-webhook.service
   
   # Install service
   sudo mv trading-webhook.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable trading-webhook
   sudo systemctl start trading-webhook
   
   # Check status
   sudo systemctl status trading-webhook
   ```

4. **Configure Security Group:**
   - Allow inbound traffic on port 3000 (or your chosen port)
   - Restrict source to TradingView webhook IPs if needed

## TradingView Webhook Setup

1. In TradingView, go to your strategy
2. Add webhook URL: `http://your-ec2-ip:3000/webhook`
3. Use this message format:
   ```json
   {
     "action": "{{strategy.order.action}}",
     "ticker": "{{ticker}}",
     "price": "{{strategy.order.price}}"
   }
   ```

## Security Considerations

- Use HTTPS in production (add reverse proxy like nginx)
- Implement webhook authentication/validation
- Use environment variables for sensitive data
- Consider IP whitelisting for webhook endpoints
- Switch to live trading API only when ready

## Monitoring

- Check logs: `sudo journalctl -u trading-webhook -f`
- Monitor service: `sudo systemctl status trading-webhook`
- Health check: `curl http://localhost:3000/health`

## Configuration

The server uses paper trading by default. To switch to live trading:

1. Change the `base_url` in `src/main.rs` from `https://paper-api.alpaca.markets` to `https://api.alpaca.markets`
2. Rebuild and redeploy

## Order Configuration

Current default settings:
- Quantity: 1 share per order
- Order type: Limit order
- Time in force: Day

These can be modified in the `handle_webhook` function in `src/main.rs`.

## Troubleshooting

1. **Server won't start:** Check environment variables and port availability
2. **Orders not placing:** Verify Alpaca API keys and account status
3. **Webhook not received:** Check EC2 security group and TradingView webhook configuration
4. **Cross-compilation issues:** Ensure you have the required target installed: `rustup target add x86_64-unknown-linux-gnu`
