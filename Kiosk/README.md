# Vending Machine Kiosk

The customer-facing self-checkout application designed for an Android tablet (specifically optimized for Samsung OLED screens).

## Features
*   **Continuous Scanning:** Always-on barcode scanner for rapid item entry.
*   **Shopping Cart:** Real-time list of scanned items and total calculation.
*   **Payment:** Displays the store's payment QR code for the customer to scan with their banking app.
*   **OLED Optimization:** Dark theme with pure black backgrounds to save battery and prevent burn-in.
*   **Admin Confirmation:** Hidden feature to reset the transaction.
    *   **Action:** Tap the QR code/image area 5 times.
    *   **PIN:** `1234` (hardcoded for v0.1.0).

## Tech Stack
*   **Framework:** Flutter
*   **Scanning:** `mobile_scanner`
*   **QR Display:** `qr_flutter` (and `Image.memory` for custom QR images)
*   **Networking:** `http`
*   **Local Storage:** `hive`

## Setup & Run
1.  Ensure the **Server** is running at `http://127.0.0.1:8080`.
    *   *Note: Update `baseUrl` in `lib/services/api_service.dart` if running on a real device.*
2.  Navigate to the `Kiosk` directory:
    ```bash
    cd Kiosk
    ```
3.  Install dependencies:
    ```bash
    flutter pub get
    ```
4.  Run the app:
    ```bash
    flutter run
    ```

## Permissions
*   **Camera:** Required for scanning barcodes.
