use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Product {
    pub barcode: String,
    pub name: String,
    pub price: f64,
    pub last_updated: i64,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct PaymentQrCode {
    pub id: String,
    pub data: String, // Base64 encoded image
    pub last_updated: i64,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct ProductPayload {
    pub barcode: String,
    pub name: String,
    pub price: f64,
}
