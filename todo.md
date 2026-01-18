# Todo List

## Version 0.3.0 (Planned)

### Phase 9: API Middleware & Custom Integration
- [x] **Database Schema:** Update `products` table to include `brand`, `size`, `type` columns.
- [x] **Model Update:** Update `Product` model to reflect new fields.
- [x] **Middleware Interface:** Define `ProductMiddleware` abstract class for data mapping.
- [x] **Implementation:** Create `OpenFoodFactsMiddleware` and `CustomApiMiddleware` (mapping your specific JSON fields).
- [x] **Service Update:** Refactor `ApiService` to use the selected middleware.

## Version 0.2.0 (Completed)

### Phase 6: Internationalization (I18n)
- [x] **Dependencies:** Add `flutter_localizations`, `intl` to Kiosk and Manager.
- [x] **Setup:** Configure `l10n.yaml` and Arb files.
- [x] **Implementation:** Replace hardcoded strings with localized strings in Kiosk and Manager.

### Phase 7: Manager-Kiosk Direct Sync Architecture
- [x] **Kiosk DB:** Migrate Kiosk to `sqflite`.
- [x] **Kiosk Server:** Implement embedded HTTP server (`shelf`) on Kiosk to accept sync requests.
- [x] **Kiosk Security:** Implement "Set PIN" screen and PIN verification middleware for the server.
- [x] **Manager DB:** Migrate Manager to `sqflite`.
- [x] **Manager Discovery:** Add "Add Kiosk" feature (IP + PIN).
- [x] **Sync Logic:** Implement "Push to Kiosk" (Manager -> Kiosk) and "Pull Stats" (Kiosk -> Manager).
- [x] **Status UI:** Add connection status indicator in Manager.

### Phase 8: Settings & External API Config
- [x] **Manager Settings:** Add screen to configure "Product Lookup API URL".
- [x] **Logic:** Update Product Service to use the configured API URL.

## Version 0.1.0 (Completed)

### Phase 1: Project Scaffolding
- [x] **Server:** Create a new binary Rust project in `Server/` (`cargo new Server --bin`).
- [x] **Manager App:** Create a new Flutter project in `Manager/` (`flutter create --template=app --empty`).
- [x] **Kiosk App:** Create a new Flutter project in `Kiosk/` (`flutter create --template=app --empty`).
- [x] **Metadata:** Update `pubspec.yaml` and `Cargo.toml` to version `0.1.0`.
- [x] **Documentation:** Update `README.md` and create `CHANGELOG.md` for all projects.
- [x] **Commit:** Initial commit of the project shells.

### Phase 2: Server API Implementation (Rust)
- [x] **Dependencies:** Add `actix-web`, `serde`, `rusqlite`, `reqwest`.
- [x] **Models:** Define `Product` and `PaymentQrCode` structs.
- [x] **Database:** Setup SQLite connection and tables.
- [x] **API:** Implement endpoints (`/products`, `/payment_qr`).
- [x] **Logic:** Implement external API lookup for products.
- [x] **Tests:** Write unit tests for API handlers.

### Phase 3: Manager App - Product Management UI
- [x] **Dependencies:** Add `mobile_scanner`, `http`, `hive`.
- [x] **Service:** Create API service for server communication.
- [x] **UI:** Build Product List, Add/Edit Product (with scanning), and QR Code Upload screens.
- [x] **Cache:** Implement local caching with Hive.

### Phase 4: Kiosk App - Customer Checkout Flow
- [x] **Dependencies:** Add `mobile_scanner`, `qr_flutter`, `http`, `hive`.
- [x] **Theme:** Implement OLED-optimized dark theme.
- [x] **UI:** Build Main Scanning screen, Payment QR display, and Admin Confirmation.

### Phase 5: Finalization
- [x] **Docs:** Create comprehensive `README.md` for each project.
- [x] **Overview:** Create `GEMINI.md` describing the architecture.
- [x] **Review:** Final verification and user approval.
