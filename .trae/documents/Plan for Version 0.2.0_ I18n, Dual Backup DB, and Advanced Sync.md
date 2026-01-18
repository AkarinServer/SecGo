I will implement Version 0.2.0 with the following plan:

1.  **Documentation Update:** Update `DESIGN.md` and `todo.md` to reflect the new architecture (Dual Backup, I18n, Sync).
2.  **Phase 6: Internationalization (I18n):**
    *   Add `flutter_localizations`, `intl` to Kiosk and Manager.
    *   Create base localization files (English).
3.  **Phase 7: Database Migration & Dual Backup:**
    *   **Server:** Update API to support sync (e.g., bulk product fetch, order upload).
    *   **Kiosk/Manager:** Migrate from Hive to `sqflite` (SQLite) to match Server schema.
    *   **Sync Logic:** Implement logic to fetch data from Server and store locally, allowing offline operation.
4.  **Phase 8: Kiosk Settings & Manager Control:**
    *   **Kiosk:** Add Settings screen with QR code (containing IP/Info).
    *   **Manager:** Add feature to scan Kiosk QR and push configuration/trigger sync.

I will start by updating the documentation and task list.