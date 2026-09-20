# Design Spec: Standalone Bank Notification Listener & Parser Module

- **Date:** 2026-09-19
- **Author:** Antigravity AI
- **Project Context:** Companion/standalone module for `App_Quan_ly_chi_tieu_ca_nhan`
- **Target Platform:** Android APK (Flutter + Kotlin Native `NotificationListenerService`)
- **Location:** `/home/chinhan/bank_notification_listener`

---

## 1. Problem Statement & Motivation
Users of personal finance apps frequently forget to manually record transactions after making purchases, transfers, or receiving money.
Android provides `NotificationListenerService`, enabling an app (with explicit user permission) to listen to status bar notifications.
By listening to all device notifications and specifically parsing banking/e-wallet transaction notifications (e.g. Vietcombank, MB Bank, Techcombank, VPBank, ACB, TPBank, BIDV, MoMo, etc.), the application can automatically capture:
- Transaction amount
- Type: `credit` (thu nhập/tiền vào) or `debit` (chi tiêu/tiền ra)
- Account / card identifier
- Transaction content / note
- Post-transaction balance
- Timestamp

Before embedding directly into the main production app `App_Quan_ly_chi_tieu_ca_nhan`, the user requests a **standalone tool/module** targeting Android APK to test notification interception, real-time logging, and parsing output fidelity.

---

## 2. Architecture & Tech Stack

### 2.1 Technology Stack
- **Framework:** Flutter (Dart 3.x / Flutter 3.38.x) - same stack as the main application.
- **Native Android Layer:** Kotlin, implementing `NotificationListenerService`.
- **Inter-process / Channel Communication:**
  - `EventChannel("vn.finance.notification_listener/events")`: Streams real-time incoming notification events (package, title, text, subText, timestamp) from Android to Flutter Dart.
  - `MethodChannel("vn.finance.notification_listener/methods")`: Checks if notification listener permission is granted; triggers intent to open system Notification Access settings (`android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS`).
- **Core Parser Engine:** Pure Dart service (`BankNotificationParser`), zero external native dependencies, allowing direct copy-paste into the main app later.

### 2.2 Project Structure
```text
/home/chinhan/bank_notification_listener/
├── android/
│   ├── app/src/main/
│   │   ├── AndroidManifest.xml          # Declares NotificationListenerService & permission
│   │   └── kotlin/.../
│   │       ├── MainActivity.kt          # EventChannel & MethodChannel handlers
│   │       └── NotificationListener.kt  # NotificationListenerService implementation
├── lib/
│   ├── main.dart                        # Application entry & theme
│   ├── models/
│   │   ├── raw_notification.dart        # DTO for incoming OS notifications
│   │   └── parsed_transaction.dart      # Schema-compatible with App_Quan_ly_chi_tieu_ca_nhan
│   ├── services/
│   │   ├── notification_bridge.dart     # Native EventChannel listener & permission manager
│   │   ├── bank_notification_parser.dart # Rule & regex-based parser for VN banks
│   │   └── mock_bank_samples.dart       # Realistic test payloads for instant offline testing
│   └── screens/
│       ├── monitor_screen.dart          # Realtime feed, filter toggles, details dialog
│       └── components/
│           ├── transaction_card.dart    # Visual card showing parsed status & tags
│           └── simulation_bar.dart      # Interactive buttons to inject bank test notifications
```

---

## 3. Data Models & Compatibility with Main App

### 3.1 Raw Notification Model (`raw_notification.dart`)
```dart
class RawNotification {
  final String id;
  final String packageName;
  final String title;
  final String text;
  final String? subText;
  final int timestamp;
  final bool isBankNotification;
}
```

### 3.2 Parsed Transaction Model (`parsed_transaction.dart`)
Matches the Firestore document schema used by `App_Quan_ly_chi_tieu_ca_nhan`:
```dart
class ParsedTransaction {
  final String id;              // UUID
  final String title;           // Bank name (e.g., 'Vietcombank', 'MBBank')
  final int amount;             // Normalized integer in VND (e.g., 50000)
  final String type;            // 'credit' (thu nhập / tiền vào) | 'debit' (chi tiêu / tiền ra)
  final int timestamp;          // millisecondsSinceEpoch
  final String category;        // Default or inferred category (e.g. 'Chuyển tiền', 'Mua sắm')
  final String note;            // Transaction description / narration
  final String? accountNumber;  // Masked account number (e.g., '...1234')
  final int? balance;           // Remaining account balance after transaction
  final String rawContent;      // Original notification string for debugging
  final double confidence;      // Parsing confidence score (0.0 to 1.0)
}
```

---

## 4. Banking Regex & Parsing Logic
The engine recognizes patterns across top Vietnamese banks and financial apps:

| Bank / App | Package Name / Sender | Type Detection Pattern | Amount Pattern | Content / Narration Pattern |
|---|---|---|---|---|
| **Vietcombank** | `com.VCB` / `Vietcombank` | `+` / `tang` / `nhan` -> `credit`<br>`-` / `giam` / `thanh toan` -> `debit` | `[+-]?([\d\.,]+)\s*(VND\|đ)` | `ND: (.*?)(\.\|$)` |
| **MB Bank** | `com.mbmobile` / `MBBank` | `+` -> `credit`<br>`-` -> `debit` | `GD:\s*[+-]?([\d\.,]+)\s*VND` | `ND:\s*(.*?)(\.\|SD\|$)` |
| **Techcombank** | `com.techcombank.mobile` | `+` / `nhan duoc` -> `credit`<br>`-` / `chuyen thanh cong` -> `debit` | `[+-]?([\d\.,]+)\s*VND` | `Noi dung:\s*(.*)` |
| **VPBank** | `com.vnpay.vpbankonline` | `+` / `tang` -> `credit`<br>`-` / `giam` -> `debit` | `PS:\s*[+-]?([\d\.,]+)\s*VND` | `ND:\s*(.*)` |
| **ACB** | `mobile.acb.com.vn` | `+` -> `credit`<br>`-` -> `debit` | `[+-]?([\d\.,]+)\s*VND` | `ND:\s*(.*)` |
| **TPBank** | `com.tpb.mb.gprsandroid` | `+` -> `credit`<br>`-` -> `debit` | `[+-]?([\d\.,]+)\s*VND` | `ND:\s*(.*)` |
| **MoMo** | `com.mservice.momotransfer` | `Nhận tiền` / `Hoàn tiền` -> `credit`<br>`Thanh toán` / `Chuyển tiền` -> `debit` | `([\d\.,]+)\s*đ` | `Lời nhắn: (.*)` |
| **ZaloPay** | `vn.com.vng.zalopay` | `Nhận được` -> `credit`<br>`Thanh toán` -> `debit` | `([\d\.,]+)\s*đ` | `Nội dung: (.*)` |
| **Generic / All Apps** | Any package | Keywords: `+`, `nhan`, `chuyen vao` -> `credit`<br>`-`, `thanh toan`, `tru` -> `debit` | `\b\d{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?\s*(?:VND\|VNĐ\|đ\|k)\b` | Full body text |

---

## 5. UI / UX Features for Testing & Validation
1. **Permission Banner / Status Indicator:**
   - Green indicator if `NotificationListenerService` is active.
   - One-tap button "Cấp quyền truy cập thông báo" (opens system settings directly) if not active.
2. **Realtime Stream Feed:**
   - Cards displaying incoming notifications as they happen.
   - Filter chips: `Tất cả` (All notifications) vs `Chỉ ngân hàng` (Bank transactions only).
3. **Simulation Bar (Test Không Cần Chuyển Tiền Thật):**
   - Instant 1-click test buttons for: VCB (+200k & -50k), MBBank (+1.5M & -35k trà sữa), Techcombank, VPBank, MoMo.
4. **Parsed JSON Viewer & Copy:**
   - Tap any notification card to open a modal with formatted JSON matching the main app's Firestore transaction schema, with 1-tap "Sao chép JSON".
5. **Clear / Export History:**
   - Button to clear current list or inspect raw stream logs.

---

## 6. Migration / Future Integration Path
When ready to merge into `App_Quan_ly_chi_tieu_ca_nhan`:
1. Copy `android/.../NotificationListener.kt` into the main app's `android/` source tree.
2. Register the service in the main app's `AndroidManifest.xml`.
3. Copy `lib/services/bank_notification_parser.dart` and `lib/services/notification_bridge.dart` into `App_Quan_ly_chi_tieu_ca_nhan/lib/services/`.
4. Connect the incoming `ParsedTransaction` event stream directly to `Db().users.doc(userId).collection('transactions').doc(id).set(...)` with optional user confirmation dialog.

---

## 7. Verification Plan
1. **Unit / Integration Tests:**
   - Run a test suite with 15+ real-world bank notification SMS/App texts.
   - Verify 100% correct parsing of amount, transaction type (`credit`/`debit`), account number, note, and balance.
2. **Flutter Build & Run Test:**
   - `flutter analyze` clean.
   - Build debug APK or run on connected device/emulator.
