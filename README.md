# SecGo — Offline-First Self‑Checkout for Convenience Stores

[English](README.md) | [中文](README_zh.md)

![CI](https://github.com/AkarinServer/SecGo/actions/workflows/ci.yml/badge.svg)
![Release](https://github.com/AkarinServer/SecGo/actions/workflows/release.yml/badge.svg)

<img alt="SecGo Horizontal Lockup" src="assets/branding/secgo-lockup.png" width="720" />

SecGo is a complete self‑checkout ecosystem for small supermarkets and convenience stores. It ships with two Flutter apps (Manager + Kiosk) and optional server components. The system is designed to keep working **offline**, with **QR-based pairing** and **peer‑to‑peer sync**.

---

## ✨ What’s Included

| Component | Role | Highlights |
| --- | --- | --- |
| **Manager App** | Store owner app | Product management, QR upload, kiosk sync, backups |
| **Kiosk App** | Customer tablet app | Continuous scan, cart, QR payment, offline mode |
| **Server (optional)** | Legacy/central backend | API lookup & QR storage (optional) |

---

## 🧭 Key Features

### 🏢 Manager App (Store Owner)
- **Product management**: scan barcodes, auto‑fill via API
- **Kiosk pairing**: QR scan to pair instantly
- **Sync & backup**: push products, backup/restore kiosk data
- **Offline‑first**: local DB with optional API enrichment

### 🛒 Kiosk App (Customer)
- **Fast checkout**: continuous scan with real‑time cart
- **Payment**: merchant QR display
- **Admin mode**: hidden gesture + PIN
- **Embedded server**: receives updates from Manager
- **Kiosk‑friendly UI**: tablet‑optimized + screensaver

---

## 🔗 Sync Flow (QR Pairing)
1. **Kiosk** → Settings → Start server (PIN required)
2. **Manager** → Pair Kiosk → Scan QR
3. **Manager** pushes products to Kiosk

---

## 🧰 Environment Variables

### Manager (`Manager/.env`)
```
ALI_CLOUD_APP_CODE=your_api_key_here
STORE_NAME=YOUR_STORE_NAME
```

### Kiosk (`Kiosk/.env`)
```
STORE_NAME=YOUR_STORE_NAME
```

> Templates live at `Manager/.env_template` and `Kiosk/.env_template`.

---

## ▶️ Quick Start

### 1) Run Manager
```bash
cd Manager
flutter pub get
flutter run
```

### 2) Run Kiosk
```bash
cd Kiosk
flutter pub get
flutter run
```

---

## 🤖 CI & Release Automation

- **CI** runs on every push/PR: lint + tests for Kiosk/Manager.
- **Release** runs on every push to `main`, builds release APKs, and publishes a GitHub Release with artifacts.

---

## 📁 Repository Layout

```
Manager/   # Store owner app
Kiosk/     # Customer kiosk app
Server/    # Optional Rust backend
.github/   # CI & release workflows
```

---

## 📝 License

MIT — see [LICENSE](LICENSE).
