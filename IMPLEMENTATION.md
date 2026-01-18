# Implementation Plan: Vending Machine Ecosystem

This document outlines the phased implementation plan for building the Server, Manage App, and Kiosk App.

## Journal

This section will be updated chronologically after each phase to log actions, learnings, surprises, and any deviations from the plan.

*   **YYYY-MM-DD - Phase X:** (Journal entry will be added here)

---

## The Plan

*After completing a task, if you added any TODOs to the code or didn't fully implement anything, make sure to add new tasks to this plan so that you can come back and complete them later.*

### Phase 1: Project Scaffolding

The goal of this phase is to create the basic directory structure and empty project files for all three components (Server, Manager, Kiosk) and commit them to the repository.

*   [ ] **Server:** Create a new binary Rust project in the `Server/` directory using `cargo new Server --bin`.
*   [ ] **Manager App:** Create a new, empty Flutter project in the `Manager/` directory using `flutter create --template=app --empty`. This app will be for the store owner.
*   [ ] **Kiosk App:** Create a new, empty Flutter project in the `Kiosk/` directory using `flutter create --template=app --empty`. This will be the customer-facing app.
*   [ ] **Update Project Metadata:**
    *   For `Manager` and `Kiosk` apps, update `pubspec.yaml` (`description`, `version: 0.1.0`).
    *   For the `Server`, update `Cargo.toml` with `description` and `version = "0.1.0"`.
*   [ ] **Update `README.md`:** For all three projects, update the `README.md` file with a short placeholder description.
*   [ ] **Create `CHANGELOG.md`:** For all three projects, create a `CHANGELOG.md` file with an initial entry for version `0.1.0`.
*   [ ] **Initial Commit:** Commit the initial empty shell of all three projects to the current branch (`feat/vending-machine-app`).

### Phase 2: Server API Implementation (Rust)

This phase focuses on building the core REST API for the server using Rust, which will handle all business logic and data storage.

*   [ ] **Dependencies:** Add `actix-web`, `serde` (with `derive` feature), `rusqlite`, and `reqwest` to the `Server`'s `Cargo.toml`.
*   [ ] **Data Models:** Define the Rust data models (`Product`, `PaymentQrCode`) using structs and derive `Serialize`/`Deserialize` from `serde`.
*   [ ] **Database Setup:** Create a module to handle the SQLite database connection using `rusqlite` and functions to initialize the necessary tables.
*   [ ] **API Endpoints:** Implement the following API endpoints using `actix-web`:
    *   `/products` (GET, POST, PUT): For creating, retrieving, and updating products.
    *   `/products/{barcode}` (GET): Retrieves a single product by its barcode.
    *   `/payment_qr` (GET, POST): For retrieving and uploading the store's payment QR code.
*   [ ] **External API Logic:** Implement the logic to call an external product lookup API (using `reqwest`) if a scanned barcode is not found in the local database.
*   [ ] **Unit Tests:** Write basic unit tests for the API endpoint handlers.

### Phase 3: Manager App - Product Management UI

This phase implements the owner's ability to manage products via the Manager App.

*   [ ] **Dependencies:** Add `mobile_scanner`, `http`, and `hive` to the `Manager` app's `pubspec.yaml`.
*   [ ] **API Service:** Create a service class to handle all HTTP communication with the `Server`.
*   [ ] **UI - Product List:** Build a screen that displays a list of all products fetched from the server.
*   [ ] **UI - Add/Edit Product:**
    *   Create a screen that uses `mobile_scanner` to scan a barcode.
    *   Upon scan, call the server to get product details.
    *   Display a form to allow the owner to enter/edit the product's name and price.
*   [ ] **UI - QR Code Upload:** Implement a feature to allow the owner to select an image from their device and upload it to the server as the payment QR code.
*   [ ] **Local Caching:** Use `hive` to cache product data locally to improve performance.

### Phase 4: Kiosk App - Customer Checkout Flow

This phase builds the customer-facing checkout experience.

*   [ ] **Dependencies:** Add `mobile_scanner`, `qr_flutter`, `http`, and `hive` to the `Kiosk` app's `pubspec.yaml`.
*   [ ] **OLED Theme:** Implement an OLED-friendly dark theme as the default theme.
*   [ ] **API Service:** Create a service class for server communication.
*   [ ] **UI - Main Screen:**
    *   Implement `mobile_scanner` for continuous, full-screen barcode scanning.
    *   Create a UI to display the list of scanned items and the running total.
*   [ ] **UI - Payment Screen:**
    *   When the "Pay" button is pressed, navigate to a new screen.
    *   This screen will fetch the payment QR code from the server and display it prominently using `qr_flutter`.
*   [ ] **UI - Admin Confirmation:**
    *   Implement a hidden gesture (e.g., tap a corner 5 times) to reveal a PIN entry dialog.
    *   On correct PIN entry, show a "Confirm Payment" button.
    *   When pressed, this button will clear the current transaction and navigate back to the main scanning screen.

### Phase 5: Finalization and Documentation

This final phase focuses on polishing the projects and creating comprehensive documentation.

*   [ ] **`README.md`:** Create a comprehensive `README.md` file for each of the three projects (`Server`, `Manager`, `Kiosk`), explaining what it is, how to set it up, and how to run it.
*   [ ] **`GEMINI.md`:** Create a `GEMINI.md` file in the project's root directory (`/Users/lolotachibana/dev/SecGo/`) that describes the overall application, its purpose, the three-part architecture, and the layout of the files.
*   [ ] **Final Review:** Ask for a final review from the user to ensure the app meets all requirements and to ask if any final modifications are needed.

---

### Standard Post-Phase Checklist

At the end of *each* phase, perform the following steps:

*   [ ] Create/modify unit tests for the code added or modified in this phase, if relevant.
*   [ ] **For Flutter:** Run `dart fix --apply` and `flutter analyze`.
*   [ ] **For Rust:** Run `cargo fix` and `cargo check`/`cargo clippy`.
*   [ ] Run any automated tests to ensure they all pass (`flutter test` or `cargo test`).
*   [ ] **For Flutter:** Run `dart format .`.
*   [ ] **For Rust:** Run `cargo fmt`.
*   [ ] Re-read this `IMPLEMENTATION.md` file to see what, if anything, has changed.
*   [ ] Update this `IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any completed checkboxes.
*   [ ] Use `git diff` to verify the changes made, and create a suitable commit message. Present the message to the user for approval.
*   [ ] **Wait for approval.** Do not commit the changes or move on to the next phase until the user approves.
*   [ ] After committing, if the app is running, use `hot_reload` (if applicable).
