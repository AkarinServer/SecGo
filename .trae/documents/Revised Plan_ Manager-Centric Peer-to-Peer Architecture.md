This is a significant architectural simplification. I will pivot the plan to focus on a **Manager-centric** model where the "Server" is optional/deprecated for core functionality.

**New Architecture:**
*   **Kiosk:** Acts as the primary "node" for customers. It has its own database. It exposes an API/Socket for the Manager to connect to.
*   **Manager:** Acts as the "Controller". It stores the master product list. It connects directly to the Kiosk(s) on the local network.
*   **Server (Rust):** Now acts as an optional "Extension" or backup, not a dependency.
*   **Data Flow:**
    *   Manager edits data locally.
    *   On "Done", Manager pushes updates to Kiosk.
    *   Manager pulls sales data from Kiosk.

**Revised Plan for Version 0.2.0:**

1.  **Documentation Update:** Reflect this simpler, 2-app architecture.
2.  **Phase 6: I18n:** (Remains same) Add localization.
3.  **Phase 7: Database & API Migration (Manager-Kiosk Direct):**
    *   **Kiosk:**
        *   Implement local SQLite DB.
        *   Implement a simple HTTP server (using `shelf` or similar in Dart) to listen for Manager commands (`/sync`, `/config`).
        *   Add "Set PIN" screen on first run.
    *   **Manager:**
        *   Implement local SQLite DB.
        *   Add "Add Kiosk" feature: Scan Network (mDNS) or Scan QR to find Kiosk IP + Enter PIN.
        *   Implement "Connection Status" indicator.
        *   Implement "Push to Kiosk" logic on product save.
4.  **Phase 8: Settings & External API:**
    *   **Manager:** Add setting to configure "Product API URL" (e.g., OpenFoodFacts or custom).

I will update the `todo.md` to reflect this simpler, more robust peer-to-peer design.