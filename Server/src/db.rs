use rusqlite::{params, Connection, Result};
use crate::models::{Product, PaymentQrCode};
use std::time::{SystemTime, UNIX_EPOCH};

pub struct Database {
    conn: Connection,
}

impl Database {
    pub fn new(path: &str) -> Result<Self> {
        let conn = Connection::open(path)?;
        Ok(Database { conn })
    }

    pub fn init(&self) -> Result<()> {
        self.conn.execute(
            "CREATE TABLE IF NOT EXISTS products (
                barcode TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                price REAL NOT NULL,
                last_updated INTEGER NOT NULL
            )",
            [],
        )?;

        self.conn.execute(
            "CREATE TABLE IF NOT EXISTS payment_qr (
                id TEXT PRIMARY KEY,
                data TEXT NOT NULL,
                last_updated INTEGER NOT NULL
            )",
            [],
        )?;
        Ok(())
    }

    pub fn get_product(&self, barcode: &str) -> Result<Option<Product>> {
        let mut stmt = self.conn.prepare("SELECT barcode, name, price, last_updated FROM products WHERE barcode = ?1")?;
        let product_iter = stmt.query_map(params![barcode], |row| {
            Ok(Product {
                barcode: row.get(0)?,
                name: row.get(1)?,
                price: row.get(2)?,
                last_updated: row.get(3)?,
            })
        })?;

        for product in product_iter {
            return Ok(Some(product?));
        }
        Ok(None)
    }

    pub fn upsert_product(&self, product: &Product) -> Result<()> {
        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() as i64;
        self.conn.execute(
            "INSERT OR REPLACE INTO products (barcode, name, price, last_updated) VALUES (?1, ?2, ?3, ?4)",
            params![product.barcode, product.name, product.price, now],
        )?;
        Ok(())
    }

    pub fn get_payment_qr(&self) -> Result<Option<PaymentQrCode>> {
        let mut stmt = self.conn.prepare("SELECT id, data, last_updated FROM payment_qr LIMIT 1")?;
        let qr_iter = stmt.query_map([], |row| {
            Ok(PaymentQrCode {
                id: row.get(0)?,
                data: row.get(1)?,
                last_updated: row.get(2)?,
            })
        })?;

        for qr in qr_iter {
            return Ok(Some(qr?));
        }
        Ok(None)
    }

    pub fn upsert_payment_qr(&self, qr: &PaymentQrCode) -> Result<()> {
        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() as i64;
        // We only keep one QR code, so we can just delete all and insert (or use a fixed ID)
        // Using a fixed ID 'store_qr' for simplicity
        self.conn.execute("DELETE FROM payment_qr", [])?;
        self.conn.execute(
            "INSERT INTO payment_qr (id, data, last_updated) VALUES (?1, ?2, ?3)",
            params!["store_qr", qr.data, now],
        )?;
        Ok(())
    }
}
