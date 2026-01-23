## Goal
- On Android, when user taps Checkout, start a short-lived “payment watch session”.
- Only accept a *new* Alipay notification (post-checkout) containing “成功收款” whose parsed amount equals `Order.totalAmount`.
- When matched: update the order DB record with audit fields + boolean, then run existing `onPaymentConfirmed()` flow (clear cart + pop + snackbar). No new success screen.

## Current Flow Touchpoints
- Checkout triggers `_processPayment()` in [main_screen.dart](file:///Users/lolotachibana/dev/SecGo/Kiosk/lib/screens/main_screen.dart#L253-L295): create order → insert DB → navigate to [PaymentScreen](file:///Users/lolotachibana/dev/SecGo/Kiosk/lib/screens/payment_screen.dart).
- Orders table lacks required audit fields in [database_helper.dart](file:///Users/lolotachibana/dev/SecGo/Kiosk/lib/db/database_helper.dart).

## Data Model / DB Migration
- Bump DB version (currently 2) and add `ALTER TABLE orders ADD COLUMN ...` for:
  - `alipay_notify_checked_amount` (int 0/1)
  - `alipay_checkout_time_ms` (int)
  - `alipay_matched_key` (text)
  - `alipay_matched_post_time_ms` (int)
  - `alipay_matched_title` (text)
  - `alipay_matched_text` (text)
  - `alipay_matched_parsed_amount_fen` (int) (store as integer fen to avoid float issues)
- Add DB helpers:
  - `updateOrderAlipayMatch(orderId, auditFields...)`
  - `isAlipayNotificationKeyAlreadyUsed(key)` to prevent reuse across orders.

## Android Notification Capture Enhancements
- Extend `SecgoNotificationListenerService` to persist a baseline snapshot payload:
  - Store JSON array of currently active Alipay notifications (at least `{key, postTime, title, text}`) into shared prefs on every `updateState()`.
- Add a “notification posted” broadcast:
  - In `onNotificationPosted()`, if package is Alipay, broadcast a payload including `{key, postTime, title, text, package}`.
- Extend `MainActivity` MethodChannel:
  - `getActiveAlipayNotificationsSnapshot()` → returns list from shared prefs.
  - Keep existing `isNotificationListenerEnabled()` and `openNotificationListenerSettings()`.
- Extend `MainActivity` EventChannel:
  - Forward the “posted” broadcast events to Flutter so the watch session can react in near real time.

## Flutter: PaymentWatchSession (core logic)
- Implement a single-session manager class (e.g. `alipay_payment_watch_service.dart`):
  - Inputs: `orderId`, `orderAmount`, `checkoutTimeMs`, `baselineKeys`.
  - Subscribe to notification events stream.
  - Candidate is “new” only if:
    - `key` not in `baselineKeys`, AND
    - `postTime > checkoutTimeMs`.
  - Filtering:
    - package == `com.eg.android.AlipayGphone`
    - text/title contains `成功收款`
  - Parsing amount:
    - Extract number in patterns like `成功收款0.01元` (support minor variants like spaces/¥ if trivial).
    - Convert to integer fen (string-based conversion, no float tolerance).
  - Match:
    - If parsed fen equals `order.totalAmount` fen → success.
    - If parsed but mismatch → show “amount mismatch” message and continue.
  - Timeout:
    - After 5 minutes → show modal “manual/admin required” and stop listening.
  - Cancel on dispose / new checkout.

## UI Integration
- In `_processPayment()`:
  - Record `checkoutTimeMs`.
  - If Android:
    - Check NotificationListener permission.
    - If not enabled: show dialog explaining permission + buttons:
      - Open settings
      - Continue without auto-confirm (manual required)
    - If enabled: read baseline snapshot via platform method, start watch session immediately.
  - Insert order with `alipay_checkout_time_ms`.
  - Navigate to `PaymentScreen`, passing `orderId` and the watch session callbacks/state.
- In `PaymentScreen`:
  - While showing QR, also show lightweight “waiting for payment” status.
  - On match: call existing `widget.onPaymentConfirmed()`.
  - On timeout: show modal dialog; user can proceed with existing admin PIN flow.

## Verification
- Add a small debug-only path or logs to confirm:
  - Baseline keys captured.
  - Posted notification event received.
  - Parsed amount and match decision.
- Test on device:
  - Start checkout → send Alipay payment 0.01 → verify order updated + success flow.
  - Send wrong amount → verify mismatch message and still listening.
  - No payment → verify 5-minute timeout dialog.

## Files Expected To Change
- Kiosk Android:
  - [SecgoNotificationListenerService.kt](file:///Users/lolotachibana/dev/SecGo/Kiosk/android/app/src/main/kotlin/com/secgo/kiosk/SecgoNotificationListenerService.kt)
  - [MainActivity.kt](file:///Users/lolotachibana/dev/SecGo/Kiosk/android/app/src/main/kotlin/com/secgo/kiosk/MainActivity.kt)
- Kiosk Flutter:
  - [database_helper.dart](file:///Users/lolotachibana/dev/SecGo/Kiosk/lib/db/database_helper.dart)
  - [order.dart](file:///Users/lolotachibana/dev/SecGo/Kiosk/lib/models/order.dart) (add optional fields if needed)
  - [main_screen.dart](file:///Users/lolotachibana/dev/SecGo/Kiosk/lib/screens/main_screen.dart)
  - [payment_screen.dart](file:///Users/lolotachibana/dev/SecGo/Kiosk/lib/screens/payment_screen.dart)
  - Add new service file for the watch session under `Kiosk/lib/services/`.
