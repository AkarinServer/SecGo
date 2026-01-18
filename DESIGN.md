# Design Document: Vending Machine Ecosystem

## 1. Overview

This document outlines the design for a self-service vending machine and checkout system, consisting of three interconnected components: a **Server**, a **Manage App** (for the store owner), and a **Kiosk App** (for customer self-checkout). The system is designed to run within a local network, with the Kiosk App primarily targeting a Samsung OLED tablet running Android 11.

The primary goal is to enable a small supermarket to streamline product price input and allow customers to perform self-checkout by scanning barcodes and completing payments via QR codes.

## 2. Detailed Analysis of the Goal/Problem

The existing problem is the manual process of product pricing and checkout. The solution aims to automate these tasks with the following core functionalities:

*   **Product Management:** Store owners need a way to easily add, update, and manage product information (barcode, name, price, payment QR code).
*   **Barcode Scanning:** Customers need to scan product barcodes efficiently to build their shopping list. The owner also needs to scan barcodes to identify products.
*   **Self-Checkout Interface:** A clear, intuitive interface for customers to view scanned items and their running total.
*   **QR Code Payment:** The system needs to display a dynamically generated payment QR code for the total amount, which customers can scan with their personal banking apps.
*   **Transaction Confirmation:** The store owner needs a secure way to confirm successful payments and finalize transactions.
*   **Hardware Compatibility:** The Kiosk App must be optimized for a large Samsung OLED tablet running Android 11, considering UI design for screen longevity.
*   **Local Network Operation:** All components are expected to communicate primarily over a local network for reliability and performance.

### User Roles and Interactions:

#### Store Owner:
*   Uses the **Manage App** (on their personal device) to:
    *   Scan product barcodes.
    *   Query product information from the server (which may in turn query external APIs).
    *   Manually input product name/details if not found.
    *   Enter/update product prices.
    *   Upload and manage the store's payment QR code image.
    *   Push updated product data to the server.
*   Interacts with the **Kiosk App** (tablet) to:
    *   Confirm customer payments (via an administrative function).

#### Customer:
*   Interacts with the **Kiosk App** (tablet) to:
    *   Scan product barcodes for items.
    *   View a list of scanned items and a running total.
    *   Initiate payment.
    *   Scan the displayed payment QR code using their personal banking app.

## 3. Alternatives Considered

### 3.1 Two Apps with Bluetooth Synchronization vs. Central Server

*   **Initial User Suggestion (Bluetooth Sync):** The user initially proposed two separate apps (Manager and Kiosk) with data synchronization via Bluetooth.
    *   **Pros:** Clear separation of concerns, potential for manager to update from their personal device directly to the Kiosk.
    *   **Cons:** Bluetooth is notoriously complex for robust data synchronization (handling pairing, connection drops, data conflicts, limited range, and protocol development). This approach introduces significant reliability and maintenance challenges.

*   **Selected Approach (Central Server):** A central server on the local network acts as the single source of truth for all data. Both the Manage App and Kiosk App communicate with this server.
    *   **Pros:**
        *   **Reliability:** Standard HTTP/REST APIs over Wi-Fi are more reliable and easier to implement for data exchange than custom Bluetooth sync.
        *   **Scalability:** Easier to scale data storage and processing on a dedicated server.
        *   **Consistency:** Ensures both apps always have the most up-to-date product and pricing information.
        *   **Flexibility:** The server can integrate with external APIs and manage data caching independently.
        *   **Simplified App Logic:** Apps only need to focus on UI and server communication, not complex data sync protocols.
    *   **Cons:** Requires setting up and maintaining a separate server component. However, given the local network requirement, this is manageable with a dedicated low-power device.

### 3.2 Payment Processing: Direct Integration vs. QR Code

*   **Direct Integration (e.g., Credit Card Terminal):**
    *   **Pros:** Fully automated payment flow within the app.
    *   **Cons:** High complexity due to PCI compliance, integration with various payment gateways, and hardware integration with physical payment terminals.

*   **Selected Approach (Customer-Scanned QR Code):** The Kiosk App displays a merchant-provided QR code for payment.
    *   **Pros:**
        *   **Simplicity:** Avoids complex payment gateway integrations and PCI compliance issues. The app only needs to display an image.
        *   **Flexibility:** Supports various payment apps (bank apps, UPI, etc.) as long as they can scan the displayed QR code.
        *   **Low Cost:** No special payment hardware is required.
    *   **Cons:** Requires manual confirmation by the store owner, as the app has no direct knowledge of payment success from external payment apps.

## 4. Detailed Design

### 4.1 System Architecture

The system comprises three main components communicating over a local network.

```mermaid
graph TD
    subgraph Local Network
        A[Kiosk App<br>(Samsung OLED Tablet)] <--> C(Server<br>(Local Machine))
        B[Manage App<br>(Owner's Device)] <--> C
    end
    C --> D[External Product API<br>(e.g., Barcode Lookup)]
```

#### 4.1.1 Server (`Server`)

*   **Technology:** Rust with the `actix-web` framework. This provides a high-performance, safe, and concurrent backend.
*   **Role:** Acts as the central data hub and business logic processor.
*   **Data Storage:** Persistent storage for product information. `rusqlite` will be used to interact with a local SQLite database file, offering robust, transactional SQL capabilities.
*   **API Endpoints:**
    *   `/products` (GET, POST, PUT): For managing product data.
    *   `/products/{barcode}` (GET): Retrieves a single product by its barcode.
    *   `/payment_qr` (GET, POST): For retrieving and uploading the store's payment QR code.
*   **External API Integration:** Will handle calling and caching responses from external product lookup APIs (e.g., by UPC) using crates like `reqwest`.
*   **Local Network Access:** Designed to be accessible by IP address within the local network only.

#### 4.1.2 Manage App (`vending_machine_manager`)

*   **Technology:** Flutter (Android/iOS compatible).
*   **Role:** Allows the store owner to manage product data.
*   **Features:**
    *   **Barcode Scanning:** Uses the device's camera (`mobile_scanner` package) to scan product UPCs.
    *   **Product Lookup:** Sends scanned barcode to the `Server`'s `/products/scan` endpoint.
    *   **Manual Input:** Provides forms to manually enter product name and details if the server lookup fails.
    *   **Price Input/Update:** Allows the owner to set and modify prices for products.
    *   **Payment QR Code Management:** Allows the owner to upload an image of their payment QR code, which will be stored on the `Server`.
    *   **Product List:** Displays a list of all products managed by the server.
*   **Local Storage:** `Hive` for local caching of recently viewed products or settings.
*   **Network Communication:** Communicates with the `Server` via HTTP requests.

#### 4.1.3 Kiosk App (`vending_machine_kiosk`)

*   **Technology:** Flutter (Android-only, targeting Android 11+ on Samsung OLED tablet).
*   **Role:** Customer-facing self-checkout interface.
*   **Features:**
    *   **Continuous Barcode Scanning:** Utilizes the front-facing camera (`mobile_scanner` package) for efficient, continuous barcode detection. The app must remain in the foreground for camera access (Android 11 restriction).
    *   **Shopping Cart Display:** Displays a list of scanned items, their individual prices, and a running total (`TextTheme` and `ColorScheme` will be used to ensure OLED-friendly dark UI).
    *   **Payment Initiation:** A "Pay Now" button to transition to the QR code payment screen.
    *   **Payment QR Code Display:** Fetches the store's payment QR code from the `Server` and displays it using `qr_flutter` to the customer.
    *   **Admin Confirmation:** A hidden or password-protected area for the store owner to confirm payments.
*   **UI/UX:**
    *   **OLED Optimization:** Primarily dark theme with soft dark grays for backgrounds, high-contrast text, and desaturated accent colors to prevent burn-in and conserve battery.
    *   **Responsive Layout:** Designed to adapt to the large tablet screen.
    *   **Accessibility:** Adhering to contrast ratios and dynamic text scaling.
*   **Local Storage:** `Hive` for local caching of product data (to allow scanning even if the server is temporarily unreachable) and app settings.
*   **Network Communication:** Communicates with the `Server` via HTTP requests to fetch product details and the payment QR code.
*   **Android Specifics:**
    *   `armv7a` and `armv8a` support.
    *   Minimum Android 11.
    *   Camera permissions handled with `permission_handler`.

### 4.2 Data Models

#### Product Model (Managed by Server, Rust structs)
```rust
// Example structure for data interchange (e.g., with Serde)
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize)]
struct Product {
    barcode: String,       // Primary key
    name: String,
    price: f64,
    last_updated: i64, // Unix timestamp
}

#[derive(Serialize, Deserialize)]
struct PaymentQrCode {
    id: String, // Unique ID
    data: String, // Base64 encoded image
    last_updated: i64, // Unix timestamp
}
```

### 4.3 UI/UX Considerations (Kiosk App - OLED Specific)

*   **Theme:** Default to a dark theme using `ThemeData` with a `ColorScheme.fromSeed` and `brightness: Brightness.dark`.
*   **Colors:** Use `Colors.grey[900]` or similar dark grays for backgrounds instead of pure black. Text and accent colors will be chosen to provide sufficient contrast (e.g., light-colored text on dark backgrounds).
*   **Dynamic Elements:** Minimize static, bright elements to reduce OLED burn-in risk. Animations will be subtle.
*   **Font Choices:** Legible fonts that scale well.
*   **Information Hierarchy:** Clear presentation of scanned items and total.
*   **Admin Access:** A non-obvious gesture (e.g., multi-tap in a corner) combined with a PIN code to access owner functions on the Kiosk App.

### 4.4 Future Considerations (Out of Scope for Initial Implementation)

*   **Proximity Sensor:** Integration with proximity sensors for screen on/off functionality. This would require careful handling given Android 11's background camera restrictions. Alternative non-camera-based proximity detection (e.g., dedicated sensor) might be necessary.
*   **Real-time Payment Confirmation:** Exploring webhooks or other real-time notifications from payment providers to automate payment confirmation, reducing the need for manual owner intervention.
*   **User Accounts:** For more complex multi-user management.
*   **Reporting/Analytics:** Sales data, popular products, etc.

## 5. Summary of Design

The project will be a three-part system: a **Rust (actix-web) Server** on the local network managing product data and payment QR codes, a Flutter **Manage App** for store owners to update this data, and a Flutter **Kiosk App** for customer self-checkout. The Kiosk App will feature continuous barcode scanning, a clear UI optimized for OLED screens, and display a QR code for customer payment, requiring owner confirmation. All components will communicate via HTTP with the central server.

## 6. References to Research URLs

#### Rust Web Server Frameworks:
*   [actix-web Documentation](https://actix.rs/) (primary choice for server)
*   [axum Documentation](https://docs.rs/axum/latest/axum/) (alternative for server)
*   [rusqlite crate](https://crates.io/crates/rusqlite) (for SQLite integration)

#### Flutter Barcode Scanning:
*   [mobile_scanner package](https://pub.dev/packages/mobile_scanner) (primary choice for barcode scanning)

#### Flutter Local Database:
*   [Hive package](https://pub.dev/packages/hive) (primary choice for local NoSQL database)
*   [sqflite package](https://pub.dev/packages/sqflite) (alternative for local SQL database)
*   [Flutter Local Database Comparison](https://dinkomarinac.dev/posts/flutter-local-database-comparison)

#### Flutter OLED UI Design:
*   [Medium article on OLED Dark Mode](https://medium.com/@innoventixsolutions/dark-mode-in-flutter-design-for-oled-screens-80b67812f86e)
*   [Vibe-studio.ai on OLED best practices](https://vibe-studio.ai/post/flutter-ui-design-best-practices-for-oled-screens)

#### Android 11 Camera Permissions:
*   [permission_handler package](https://pub.dev/packages/permission_handler)
*   [Medium article on Android 11 Camera Restrictions](https://medium.com/flutter-community/android-11-camera-permissions-in-flutter-36f78a7c29e7)

#### Flutter Display Payment QR Code:
*   [qr_flutter package](https://pub.dev/packages/qr_flutter)
*   [Example of QR code payment display](https://medium.com/@flutter_team/how-to-display-a-payment-qr-code-in-flutter-57e0f2d4d9b4)
