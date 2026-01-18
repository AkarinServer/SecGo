use actix_web::{web, HttpResponse, Responder};
use crate::db::Database;
use crate::models::{Product, ProductPayload, PaymentQrCode};
use std::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH};
use serde::Deserialize;

pub struct AppState {
    pub db: Mutex<Database>,
}

pub async fn get_product(
    data: web::Data<AppState>,
    path: web::Path<String>,
) -> impl Responder {
    let barcode = path.into_inner();
    
    // 1. Try local DB
    {
        let db = data.db.lock().unwrap();
        match db.get_product(&barcode) {
            Ok(Some(product)) => return HttpResponse::Ok().json(product),
            Ok(None) => {} // Not found locally, proceed to external
            Err(_) => return HttpResponse::InternalServerError().finish(),
        }
    } // Drop lock

    // 2. Try external API
    if let Some(product) = lookup_external_product(&barcode).await {
        // 3. Save to local DB
        let db = data.db.lock().unwrap();
        if let Err(e) = db.upsert_product(&product) {
            eprintln!("Failed to cache external product: {}", e);
        }
        return HttpResponse::Ok().json(product);
    }

    HttpResponse::NotFound().body("Product not found")
}

pub async fn add_product(
    data: web::Data<AppState>,
    payload: web::Json<ProductPayload>,
) -> impl Responder {
    let db = data.db.lock().unwrap();
    let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() as i64;
    
    let product = Product {
        barcode: payload.barcode.clone(),
        name: payload.name.clone(),
        price: payload.price,
        last_updated: now,
    };

    match db.upsert_product(&product) {
        Ok(_) => HttpResponse::Ok().json(product),
        Err(_) => HttpResponse::InternalServerError().finish(),
    }
}

pub async fn get_payment_qr(data: web::Data<AppState>) -> impl Responder {
    let db = data.db.lock().unwrap();
    match db.get_payment_qr() {
        Ok(Some(qr)) => HttpResponse::Ok().json(qr),
        Ok(None) => HttpResponse::NotFound().body("QR code not set"),
        Err(_) => HttpResponse::InternalServerError().finish(),
    }
}

pub async fn set_payment_qr(
    data: web::Data<AppState>,
    payload: web::Json<PaymentQrCode>,
) -> impl Responder {
    let db = data.db.lock().unwrap();
    // Force ID to be store_qr regardless of input to maintain singleton
    let qr = PaymentQrCode {
        id: "store_qr".to_string(),
        data: payload.data.clone(),
        last_updated: SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() as i64,
    };

    match db.upsert_payment_qr(&qr) {
        Ok(_) => HttpResponse::Ok().json(qr),
        Err(_) => HttpResponse::InternalServerError().finish(),
    }
}

// External API lookup logic
#[derive(Deserialize)]
struct OffProductResponse {
    product: Option<OffProduct>,
    status: i32,
}

#[derive(Deserialize)]
struct OffProduct {
    product_name: Option<String>,
}

pub async fn lookup_external_product(barcode: &str) -> Option<Product> {
    println!("Looking up external product for barcode: {}", barcode);
    
    let url = format!("https://world.openfoodfacts.org/api/v0/product/{}.json", barcode);
    
    match reqwest::get(&url).await {
        Ok(resp) => {
            match resp.json::<OffProductResponse>().await {
                Ok(data) => {
                    if data.status == 1 {
                        if let Some(p) = data.product {
                            let name = p.product_name.unwrap_or_else(|| "Unknown Product".to_string());
                            let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() as i64;
                            return Some(Product {
                                barcode: barcode.to_string(),
                                name,
                                price: 0.0, // External API doesn't provide price
                                last_updated: now,
                            });
                        }
                    }
                },
                Err(e) => eprintln!("Failed to parse external API response: {}", e),
            }
        },
        Err(e) => eprintln!("Failed to call external API: {}", e),
    }

    None
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::{test, App};
    
    #[actix_web::test]
    async fn test_add_get_product() {
        // Use in-memory DB for testing
        let db = Database::new(":memory:").unwrap();
        db.init().unwrap();
        let app_state = web::Data::new(AppState { db: Mutex::new(db) });

        let app = test::init_service(
            App::new()
                .app_data(app_state.clone())
                .route("/products", web::post().to(add_product))
                .route("/products/{barcode}", web::get().to(get_product))
        ).await;

        // 1. Add Product
        let payload = ProductPayload {
            barcode: "12345".to_string(),
            name: "Test Item".to_string(),
            price: 9.99,
        };
        
        let req = test::TestRequest::post()
            .uri("/products")
            .set_json(&payload)
            .to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());

        // 2. Get Product
        let req = test::TestRequest::get()
            .uri("/products/12345")
            .to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
        
        let result: Product = test::read_body_json(resp).await;
        assert_eq!(result.name, "Test Item");
        assert_eq!(result.price, 9.99);
    }
}
