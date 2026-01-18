# Constitution: Vending Machine Ecosystem

## 1. Overview & Project Goals

This document is the master plan for creating a self-service vending machine and checkout system. It serves as the single source of truth for the project's design, architecture, and implementation plan.

The project consists of three interconnected components: a **Server**, a **Manage App** (for the store owner), and a **Kiosk App** (for customer self-checkout). The system is designed to run within a local network.

The primary goal is to enable a small supermarket to streamline product price input and allow customers to perform self-checkout by scanning barcodes and completing payments via QR codes.

### 1.1. Core Requirements

*   **Product Management:** The store owner must be able to easily add, update, and manage product information (barcode, name, price).
*   **Payment QR Code:** The owner must be able to upload their store's payment QR code.
*   **Self-Checkout:** Customers must be able to scan product barcodes, see a running total, and be presented with the QR code for payment.
*   **Transaction Confirmation:** The owner must have a secure way to confirm that a customer's payment has been received.
*   **Local Network:** All components must operate reliably on a local Wi-Fi network.
*   **Hardware & OS:**
    *   The Kiosk App is primarily for a large Samsung OLED tablet running Android 11.
    *   The UI must be optimized to conserve the lifespan of the OLED screen (e.g., dark mode).
    *   The Flutter apps must support `armv7a` and `armv8a` architectures.

## 2. Architecture and Detailed Design

### 2.1. System Architecture

The system is a three-part client-server architecture operating on a local network.

```mermaid
graph TD
    subgraph "Local Network"
        A[Kiosk App<br>(Samsung OLED Tablet)] <--> C(Server<br>(Rust / actix-web))
        B[Manage App<br>(Owner's Device)] <--> C
    end
    C --> D[External Product API<br>(e.g., Barcode Lookup)]
```

### 2.2. Component Breakdown

#### 2.2.1. Server (`Server/`)

*   **Technology:** **Rust** with the **`actix-web`** framework. This provides a high-performance, safe, and concurrent backend.
*   **Role:** Acts as the central data hub and business logic processor.
*   **Data Storage:** **SQLite** database accessed via the **`rusqlite`** crate for robust, transactional SQL capabilities.
*   **API Endpoints:**
    *   `/products` (GET, POST, PUT): For managing product data.
    *   `/products/{barcode}` (GET): Retrieves a single product by its barcode.
    *   `/payment_qr` (GET, POST): For retrieving and uploading the store's payment QR code.
*   **External API Integration:** Will handle calling external product lookup APIs using the `reqwest` crate.
*   **Data Models (Rust):**
    ```rust
    use serde::{Serialize, Deserialize};

    #[derive(Serialize, Deserialize)]
    struct Product {
        barcode: String,
        name: String,
        price: f64,
        last_updated: i64, // Unix timestamp
    }

    #[derive(Serialize, Deserialize)]
    struct PaymentQrCode {
        id: String,
        data: String, // Base64 encoded image
        last_updated: i64, // Unix timestamp
    }
    ```

#### 2.2.2. Manage App (`Manager/`)

*   **Technology:** Flutter.
*   **Role:** Allows the store owner to manage product data.
*   **Features:**
    *   **Barcode Scanning:** Uses `mobile_scanner` to scan product UPCs.
    *   **Product Management:** Sends product data to the server and allows manual input/price updates.
    *   **QR Code Management:** Allows the owner to upload their payment QR code image to the server.
    *   **Local Caching:** Uses `hive` for local caching of settings.

#### 2.2.3. Kiosk App (`Kiosk/`)

*   **Technology:** Flutter (optimized for Android 11).
*   **Role:** Customer-facing self-checkout interface.
*   **Features:**
    *   **Continuous Scanning:** Uses `mobile_scanner` for continuous barcode detection. The app must remain in the foreground for camera access.
    *   **UI:** OLED-optimized dark theme. Displays a list of scanned items and a running total.
    *   **Payment Flow:** A "Pay" button transitions to a screen that displays the store's QR code (fetched from the server) using the `qr_flutter` package.
    *   **Admin Confirmation:** A hidden, PIN-protected area for the owner to confirm payment and reset the transaction.
    *   **Local Caching:** Uses `hive` to cache product data for performance and resilience.

### 2.3. Alternatives Considered

*   **Bluetooth Sync vs. Central Server:** A central server was chosen over Bluetooth for data synchronization due to its superior reliability, scalability, and simplicity for data exchange using standard HTTP protocols.
*   **Direct Payment vs. QR Code:** Displaying a merchant QR code was chosen over direct payment terminal integration to dramatically reduce complexity, cost, and PCI compliance overhead.

## 3. Phased Implementation Plan

### Journal

*This section will be updated chronologically after each phase to log actions, learnings, and deviations.*

### The Plan

*After completing a task, if you added any TODOs to the code or didn't fully implement anything, make sure to add new tasks to this plan so that you can come back and complete them later.*

#### Phase 1: Project Scaffolding

*   [ ] **Server:** Create a new binary Rust project in the `Server/` directory using `cargo new Server --bin`.
*   [ ] **Manager App:** Create a new, empty Flutter project in the `Manager/` directory using `flutter create --template=app --empty`.
*   [ ] **Kiosk App:** Create a new, empty Flutter project in the `Kiosk/` directory using `flutter create --template=app --empty`.
*   [ ] **Update Project Metadata:**
    *   For `Manager` and `Kiosk` apps, update `pubspec.yaml` (`description`, `version: 0.1.0`).
    *   For the `Server`, update `Cargo.toml` with `description` and `version = "0.1.0"`.
*   [ ] **Update `README.md`:** For all three projects, update the `README.md` file with a short placeholder description.
*   [ ] **Create `CHANGELOG.md`:** For all three projects, create a `CHANGELOG.md` file with an initial entry for version `0.1.0`.
*   [ ] **Initial Commit:** Commit the initial empty shell of all three projects to the current branch (`feat/vending-machine-app`).

#### Phase 2: Server API Implementation (Rust)

*   [ ] **Dependencies:** Add `actix-web`, `serde` (with `derive` feature), `rusqlite`, and `reqwest` to the `Server`'s `Cargo.toml`.
*   [ ] **Data Models:** Define the Rust data models (`Product`, `PaymentQrCode`) using structs and derive `Serialize`/`Deserialize`.
*   [ ] **Database Setup:** Create a module to handle the SQLite database connection using `rusqlite` and initialize tables.
*   [ ] **API Endpoints:** Implement the API endpoints (`/products`, `/products/{barcode}`, `/payment_qr`) using `actix-web`.
*   [ ] **External API Logic:** Implement logic to call an external product lookup API using `reqwest`.
*   [ ] **Unit Tests:** Write basic unit tests for the API endpoint handlers.

#### Phase 3: Manager App - Product Management UI

*   [ ] **Dependencies:** Add `mobile_scanner`, `http`, and `hive` to the `Manager` app's `pubspec.yaml`.
*   [ ] **API Service:** Create a service class to handle all HTTP communication with the `Server`.
*   [ ] **UI:** Build screens for listing products, adding/editing products (with barcode scanning), and uploading the payment QR code.
*   [ ] **Local Caching:** Use `hive` to cache product data locally.

#### Phase 4: Kiosk App - Customer Checkout Flow

*   [ ] **Dependencies:** Add `mobile_scanner`, `qr_flutter`, `http`, and `hive` to the `Kiosk` app's `pubspec.yaml`.
*   [ ] **OLED Theme:** Implement an OLED-friendly dark theme.
*   [ ] **API Service:** Create a service class for server communication.
*   [ ] **UI:** Implement the main scanning screen, the payment QR code display screen, and the hidden admin PIN/confirmation functionality.

#### Phase 5: Finalization and Documentation

*   [ ] **`README.md`:** Create a comprehensive `README.md` file for each of the three projects.
*   [ ] **`GEMINI.md`:** Create a `GEMINI.md` file in the project's root describing the overall application and architecture.
*   [ ] **Final Review:** Ask for a final review from the user.

### Standard Post-Phase Checklist

At the end of *each* phase, perform the following steps:

*   [ ] Create/modify unit tests for the code added or modified.
*   [ ] **For Flutter:** Run `dart fix --apply` and `flutter analyze`.
*   [ ] **For Rust:** Run `cargo fix` and `cargo check`/`cargo clippy`.
*   [ ] Run any automated tests (`flutter test` or `cargo test`).
*   [ ] **For Flutter:** Run `dart format .`.
*   [ ] **For Rust:** Run `cargo fmt`.
*   [ ] Re-read this `constitution.md` file to check for deviations.
*   [ ] Update this `constitution.md` file (Journal, checkboxes).
*   [ ] Use `git diff` to verify changes and create a suitable commit message for user approval.
*   [ ] **Wait for approval** before committing.
*   [ ] After committing, use `hot_reload` if applicable.

## 4. Research References

*   **Rust Web Server:** [actix-web](https://actix.rs/), [rusqlite](https://crates.io/crates/rusqlite)
*   **Flutter Barcode Scanning:** [mobile_scanner](https://pub.dev/packages/mobile_scanner)
*   **Flutter Local Database:** [Hive](https://pub.dev/packages/hive)
*   **Flutter Permissions:** [permission_handler](https://pub.dev/packages/permission_handler)
*   **Flutter QR Code Display:** [qr_flutter](https://pub.dev/packages/qr_flutter)
