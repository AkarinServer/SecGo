# Vending Machine Server

The central backend for the Vending Machine ecosystem. It manages product data, handles external API lookups, and stores the merchant's payment QR code.

## Tech Stack
*   **Language:** Rust (Edition 2021)
*   **Web Framework:** `actix-web`
*   **Database:** SQLite via `rusqlite`
*   **HTTP Client:** `reqwest`
*   **Serialization:** `serde`, `serde_json`

## API Endpoints

### Products
*   `POST /products`: Add or update a product.
    *   Body: `{"barcode": "...", "name": "...", "price": 10.5}`
*   `GET /products/{barcode}`: Get product details.
    *   Returns 200 with product JSON if found (locally or via external API).
    *   Returns 404 if not found.

### Payment QR
*   `GET /payment_qr`: Retrieve the store's payment QR code image (Base64 encoded).
*   `POST /payment_qr`: Upload a new payment QR code.
    *   Body: `{"data": "<base64_string>"}`

## Setup & Run
1.  Ensure you have Rust installed.
2.  Navigate to the `Server` directory:
    ```bash
    cd Server
    ```
3.  Run the server:
    ```bash
    cargo run
    ```
4.  The server will start at `http://127.0.0.1:8080`.

## Testing
Run unit tests:
```bash
cargo test
```
