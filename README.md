# SecGo Vending Machine Ecosystem

[中文版](README_zh.md)

A complete self-checkout solution for small supermarkets and convenience stores. The system consists of a Manager App for store owners, a Kiosk App for customers, and a robust data synchronization mechanism that works completely offline.

---

## 🚀 Features

### 🏢 Manager App (Store Owner)
*   **Product Management:** Scan barcodes to add products. Auto-fill details via Open Food Facts or custom AliCloud API.
*   **Inventory Control:** Edit prices, names, and other product details.
*   **Payment Setup:** Upload your personal/business payment QR code (WeChat Pay/Alipay/etc.).
*   **Kiosk Sync:**
    *   **Discovery:** Scan a QR code on the Kiosk to pair instantly.
    *   **Push:** Push your entire product database to the Kiosk with one tap.
    *   **Pull:** (Planned) Retrieve sales statistics and order history from the Kiosk.
*   **Offline First:** Works locally. No internet required for core functions once set up.

### 🛒 Kiosk App (Customer)
*   **Self-Checkout:** Continuous barcode scanning for a fast checkout experience.
*   **Cart System:** Real-time shopping cart with total calculation.
*   **Payment:** Displays the merchant's payment QR code for customers to scan.
*   **Admin Mode:** Hidden gesture (tap QR 5 times) + PIN protection to access settings or reset transactions.
*   **Kiosk Server:** Runs an embedded HTTP server to receive product updates from the Manager App.
*   **OLED Optimization:** Pure black dark mode to save battery and prevent burn-in on OLED tablets.

### 🌐 Universal API Middleware
*   **Flexible Backend:** Switch between different product lookup APIs in Settings.
*   **Open Food Facts:** Default free global food database.
*   **Universal API (AliCloud):** Support for generic Chinese product data via AliCloud API (requires API key).
*   **Customizable:** Easily extendable `ProductMiddleware` architecture to support *any* JSON API.

---

## 🛠 Tech Stack

*   **Language:** Dart (Flutter)
*   **State Management:** `setState` (Simple & Robust)
*   **Local Database:** `sqflite` (SQLite)
*   **Networking:** `http`, `shelf` (Embedded Server)
*   **Discovery:** QR Code based pairing
*   **Environment:** `flutter_dotenv` for secure API keys

---

## 📦 Installation & Setup

### Prerequisites
*   Flutter SDK (3.0+)
*   Android Studio / VS Code
*   Two devices (one for Manager, one for Kiosk)

### 1. Configure Environment (Manager)
Create a `.env` file in the `Manager/` directory:
```bash
ALI_CLOUD_APP_CODE=your_api_key_here
```

### 2. Run the Manager App
```bash
cd Manager
flutter pub get
flutter run
```

### 3. Run the Kiosk App
```bash
cd Kiosk
flutter pub get
flutter run
```

---

## 🔗 How to Sync (Dual Backup System)

1.  **Open Kiosk:** Go to **Settings** (Icon on main screen) -> Enter PIN -> Click **Start Server**.
2.  **Open Manager:** Click **Sync Kiosk** on the home screen.
3.  **Scan:** Use the Manager App to scan the QR code displayed on the Kiosk.
4.  **Done:** The product database is instantly transferred to the Kiosk.

---

## 📂 Project Structure

*   `Manager/`: The mobile app for store owners.
*   `Kiosk/`: The tablet app for customers.
*   `Server/`: (Optional/Legacy) Rust backend, now replaced by peer-to-peer sync.

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
