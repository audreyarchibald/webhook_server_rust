use anyhow::Result;
use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::post,
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::env;
use std::sync::Arc;
use tower_http::cors::CorsLayer;
use tracing::{error, info};

#[derive(Debug, Deserialize)]
struct WebhookRequest {
    action: String,
    ticker: String,
    price: String,
}

#[derive(Debug, Serialize)]
struct AlpacaOrderRequest {
    symbol: String,
    qty: String,
    side: String,
    #[serde(rename = "type")]
    order_type: String,
    time_in_force: String,
    limit_price: Option<String>,
}

#[derive(Clone)]
struct AppState {
    alpaca_client: Arc<AlpacaClient>,
}

struct AlpacaClient {
    api_key: String,
    secret_key: String,
    base_url: String,
    client: reqwest::Client,
}

impl AlpacaClient {
    fn new(api_key: String, secret_key: String) -> Self {
        Self {
            api_key,
            secret_key,
            base_url: "https://paper-api.alpaca.markets".to_string(), // Use paper trading by default
            client: reqwest::Client::new(),
        }
    }

    async fn place_order(&self, order: AlpacaOrderRequest) -> Result<()> {
        let url = format!("{}/v2/orders", self.base_url);
        
        info!("Placing order: {:?}", order);
        
        let response = self
            .client
            .post(&url)
            .header("APCA-API-KEY-ID", &self.api_key)
            .header("APCA-API-SECRET-KEY", &self.secret_key)
            .json(&order)
            .send()
            .await?;

        if response.status().is_success() {
            let order_response = response.text().await?;
            info!("Order placed successfully: {}", order_response);
        } else {
            let error_text = response.text().await?;
            error!("Failed to place order: {}", error_text);
            return Err(anyhow::anyhow!("Failed to place order: {}", error_text));
        }

        Ok(())
    }
}

async fn handle_webhook(
    State(state): State<AppState>,
    Json(payload): Json<WebhookRequest>,
) -> impl IntoResponse {
    info!("Received webhook: {:?}", payload);

    // Parse the action to determine buy/sell
    let side = match payload.action.to_lowercase().as_str() {
        "buy" => "buy",
        "sell" => "sell",
        _ => {
            error!("Invalid action: {}", payload.action);
            return (StatusCode::BAD_REQUEST, "Invalid action").into_response();
        }
    };

    // Create Alpaca order request
    let order = AlpacaOrderRequest {
        symbol: payload.ticker.to_uppercase(),
        qty: "1".to_string(), // Default quantity, you can make this configurable
        side: side.to_string(),
        order_type: "limit".to_string(),
        time_in_force: "day".to_string(),
        limit_price: Some(payload.price),
    };

    // Place the order
    match state.alpaca_client.place_order(order).await {
        Ok(_) => {
            info!("Order placed successfully for {}", payload.ticker);
            (StatusCode::OK, "Order placed successfully").into_response()
        }
        Err(e) => {
            error!("Failed to place order: {}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, "Failed to place order").into_response()
        }
    }
}

async fn health_check() -> impl IntoResponse {
    (StatusCode::OK, "Server is running")
}

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt::init();

    // Get environment variables
    let alpaca_api_key = env::var("ALPACA_API_KEY")
        .expect("ALPACA_API_KEY environment variable must be set");
    let alpaca_secret_key = env::var("ALPACA_SECRET_KEY")
        .expect("ALPACA_SECRET_KEY environment variable must be set");
    let port = env::var("PORT").unwrap_or_else(|_| "3000".to_string());

    // Create Alpaca client
    let alpaca_client = Arc::new(AlpacaClient::new(alpaca_api_key, alpaca_secret_key));

    // Create app state
    let state = AppState { alpaca_client };

    // Build the application
    let app = Router::new()
        .route("/webhook", post(handle_webhook))
        .route("/health", axum::routing::get(health_check))
        .layer(CorsLayer::permissive())
        .with_state(state);

    // Bind to all interfaces for EC2 deployment
    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{}", port))
        .await
        .unwrap();

    info!("Server starting on port {}", port);

    // Start the server
    axum::serve(listener, app).await.unwrap();

    Ok(())
}
