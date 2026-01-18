# GEMINI - Vending Machine Ecosystem

## Overview
This project is a complete self-checkout solution for small supermarkets. It allows a store owner to manage their inventory and pricing via a mobile app, while customers use a dedicated tablet kiosk to scan items and pay via a merchant-provided QR code.

The system is designed to operate on a **local network**, ensuring speed and reliability without dependence on external cloud services (except for optional product lookups).

## Architecture
The ecosystem consists of three main components:

1.  **Server (Rust):** The brain of the operation.
    *   **Responsibility:** Stores the "Source of Truth" for product data and the payment QR code.
    *   **Database:** SQLite.
    *   **API:** RESTful JSON API.
    *   **External Integration:** Falls back to OpenFoodFacts API for unknown barcodes.

2.  **Manager App (Flutter):** The owner's tool.
    *   **Responsibility:** Input and update data.
    *   **Key Features:** Barcode scanning, price editing, QR code image upload.

3.  **Kiosk App (Flutter):** The customer's interface.
    *   **Responsibility:** Checkout experience.
    *   **Key Features:** Continuous scanning, cart management, payment display.
    *   **Hardware Target:** Android Tablet (Samsung OLED).

## Data Flow
1.  **Owner** uses *Manager App* to scan a new item.
2.  *Manager App* queries *Server*.
3.  *Server* checks local DB. If missing, checks *OpenFoodFacts*.
4.  *Server* returns product details.
5.  **Owner** sets the price and saves.
6.  **Customer** scans the item at the *Kiosk*.
7.  *Kiosk* retrieves the price from *Server* and adds to cart.
8.  **Customer** proceeds to pay. *Kiosk* displays the *Payment QR* fetched from *Server*.
9.  **Owner** confirms payment (visually/externally) and enters PIN on *Kiosk* to reset.

## Directory Structure
*   `/Server`: Rust Actix-web project.
*   `/Manager`: Flutter mobile app project.
*   `/Kiosk`: Flutter tablet app project.
*   `todo.md`: Project task tracker.
*   `constitution.md`: Project rules and goals.
*   `DESIGN.md`: Detailed design document.
*   `IMPLEMENTATION.md`: Implementation journal and plan.
