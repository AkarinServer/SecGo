mod models;
mod db;
mod api;

use actix_web::{web, App, HttpServer};
use std::sync::Mutex;
use db::Database;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize database
    let db = Database::new("vending.db").expect("Failed to open database");
    db.init().expect("Failed to initialize database tables");
    
    let app_state = web::Data::new(api::AppState {
        db: Mutex::new(db),
    });

    println!("Server starting at http://127.0.0.1:8080");

    HttpServer::new(move || {
        App::new()
            .app_data(app_state.clone())
            .route("/products", web::post().to(api::add_product))
            .route("/products/{barcode}", web::get().to(api::get_product))
            .route("/payment_qr", web::get().to(api::get_payment_qr))
            .route("/payment_qr", web::post().to(api::set_payment_qr))
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}
