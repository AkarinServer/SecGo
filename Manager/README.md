# Vending Machine Manager

<img alt="SecGo Manager Icon" src="assets/branding/secgo-manager-icon.png" width="200" />

A Flutter application for store owners to manage their product inventory and settings.

## Features
*   **Scan & Add Products:** Scan a product barcode to add it to the system. If the product exists in the OpenFoodFacts database, details are auto-filled.
*   **Edit Prices:** Update product prices easily.
*   **Upload Payment QR:** Select an image from the gallery to set as the store's payment QR code (displayed on the Kiosk).

## Tech Stack
*   **Framework:** Flutter
*   **Scanning:** `mobile_scanner`
*   **Networking:** `http`
*   **Local Storage:** `hive`
*   **Image Picking:** `image_picker`

## Setup & Run
1.  Ensure the **Server** is running at `http://127.0.0.1:8080`.
    *   *Note: If running on Android Emulator, the app uses `10.0.2.2`. If on iOS Simulator, it uses `127.0.0.1`. For real devices, update `baseUrl` in `lib/services/api_service.dart` with your machine's local IP.*
2.  Navigate to the `Manager` directory:
    ```bash
    cd Manager
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
*   **Photo Library:** Required for uploading the QR code image.
