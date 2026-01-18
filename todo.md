# Todo List

## Version 0.1.0

### Phase 1: Project Scaffolding
- [ ] **Server:** Create a new binary Rust project in `Server/` (`cargo new Server --bin`).
- [ ] **Manager App:** Create a new Flutter project in `Manager/` (`flutter create --template=app --empty`).
- [ ] **Kiosk App:** Create a new Flutter project in `Kiosk/` (`flutter create --template=app --empty`).
- [ ] **Metadata:** Update `pubspec.yaml` and `Cargo.toml` to version `0.1.0`.
- [ ] **Documentation:** Update `README.md` and create `CHANGELOG.md` for all projects.
- [ ] **Commit:** Initial commit of the project shells.

### Phase 2: Server API Implementation (Rust)
- [ ] **Dependencies:** Add `actix-web`, `serde`, `rusqlite`, `reqwest`.
- [ ] **Models:** Define `Product` and `PaymentQrCode` structs.
- [ ] **Database:** Setup SQLite connection and tables.
- [ ] **API:** Implement endpoints (`/products`, `/payment_qr`).
- [ ] **Logic:** Implement external API lookup for products.
- [ ] **Tests:** Write unit tests for API handlers.

### Phase 3: Manager App - Product Management UI
- [ ] **Dependencies:** Add `mobile_scanner`, `http`, `hive`.
- [ ] **Service:** Create API service for server communication.
- [ ] **UI:** Build Product List, Add/Edit Product (with scanning), and QR Code Upload screens.
- [ ] **Cache:** Implement local caching with Hive.

### Phase 4: Kiosk App - Customer Checkout Flow
- [ ] **Dependencies:** Add `mobile_scanner`, `qr_flutter`, `http`, `hive`.
- [ ] **Theme:** Implement OLED-optimized dark theme.
- [ ] **UI:** Build Main Scanning screen, Payment QR display, and Admin Confirmation.

### Phase 5: Finalization
- [ ] **Docs:** Create comprehensive `README.md` for each project.
- [ ] **Overview:** Create `GEMINI.md` describing the architecture.
- [ ] **Review:** Final verification and user approval.
