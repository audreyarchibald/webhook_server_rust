# Multi-stage build for x86_64 Linux
FROM rust:1.75 as builder

# Create app directory
WORKDIR /app

# Copy manifest files first for better caching
COPY Cargo.toml ./

# Create a dummy main.rs to build dependencies
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm -rf src

# Copy actual source code
COPY src ./src

# Build the actual application
RUN cargo build --release

# Runtime stage
FROM debian:bullseye-slim

# Install ca-certificates for HTTPS requests
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy the binary from builder stage
COPY --from=builder /app/target/release/trading_webhook_server /app/

# Expose port
EXPOSE 3000

# Run the application
CMD ["./trading_webhook_server"]
