# Bank Notification Listener Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone Flutter Android APK application (`bank_notification_listener`) that intercepts system notifications via Android `NotificationListenerService`, filters and parses banking/e-wallet transactions (VCB, MB, Techcombank, VPBank, ACB, TPBank, BIDV, MoMo, etc.) into structured income/expense (`credit`/`debit`) transactions matching the schema of `App_Quan_ly_chi_tieu_ca_nhan`, with a real-time monitor UI and mock simulation suite.

**Architecture:** A Flutter application hosting a lightweight Android Native Kotlin `NotificationListenerService`. Incoming notifications are streamed over an `EventChannel` to Dart. A pure-Dart regex engine (`BankNotificationParser`) extracts amount, credit/debit type, account, content, and balance. The UI provides a real-time feed, permission controls, and simulation buttons for instant testing.

**Tech Stack:** Flutter 3.38+, Dart 3.10+, Android Kotlin, Android `NotificationListenerService`, EventChannel & MethodChannel, `intl`, `uuid`.

**Spec:** `/home/chinhan/Applications/App_Quan_ly_chi_tieu_ca_nhan/docs/superpowers/specs/2026-09-19-bank-notification-listener-design.md`

## Global Constraints
- Target directory: `/home/chinhan/bank_notification_listener`
- Tech stack: 100% Flutter project with Kotlin Android platform runner
- Compatibility: Output schema matches `App_Quan_ly_chi_tieu_ca_nhan` transactions (`id`, `title`, `amount`, `type: 'credit' | 'debit'`, `timestamp`, `category`, `note`)
- No heavy third-party plugins with brittle Gradle versions; use clean native channels.

---

### Task 1: Flutter Project Scaffolding & Base Setup

**Files:**
- Create: `/home/chinhan/bank_notification_listener/pubspec.yaml`
- Create: `/home/chinhan/bank_notification_listener/lib/main.dart`

**Interfaces:**
- Consumes: Flutter SDK
- Produces: Base project structure and dependencies

- [ ] **Step 1: Scaffold Flutter project via CLI**
```bash
flutter create --org vn.finance --platforms android bank_notification_listener
```

- [ ] **Step 2: Add essential dependencies to `pubspec.yaml`**
Add `intl: ^0.20.2` and `uuid: ^4.3.3` to `pubspec.yaml`.

- [ ] **Step 3: Run `flutter pub get`**
Run: `cd /home/chinhan/bank_notification_listener && flutter pub get`
Expected: Resolution succeeded.

---

### Task 2: Core Data Models (`RawNotification`, `ParsedTransaction`)

**Files:**
- Create: `/home/chinhan/bank_notification_listener/lib/models/raw_notification.dart`
- Create: `/home/chinhan/bank_notification_listener/lib/models/parsed_transaction.dart`
- Test: `/home/chinhan/bank_notification_listener/test/models/transaction_models_test.dart`

**Interfaces:**
- Produces: `RawNotification`, `ParsedTransaction` classes with `toMap()`, `toJson()`, `fromMap()`.

- [ ] **Step 1: Write test for models**
Create `test/models/transaction_models_test.dart` testing serialization, schema validation, and copyWith.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/models/transaction_models_test.dart`
Expected: FAIL (files missing).

- [ ] **Step 3: Implement `RawNotification` and `ParsedTransaction`**
Implement data models with fields strictly matching `App_Quan_ly_chi_tieu_ca_nhan` transaction schema.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/models/transaction_models_test.dart`
Expected: PASS.

---

### Task 3: Bank Notification Parser Engine (`BankNotificationParser`)

**Files:**
- Create: `/home/chinhan/bank_notification_listener/lib/services/bank_notification_parser.dart`
- Test: `/home/chinhan/bank_notification_listener/test/services/bank_notification_parser_test.dart`

**Interfaces:**
- Consumes: `RawNotification`
- Produces: `BankNotificationParser.parse(RawNotification notification) -> ParsedTransaction?`

- [ ] **Step 1: Write comprehensive test cases with real VN bank notifications**
Include samples for:
- Vietcombank (`+50,000VND`, `-120,000VND`)
- MB Bank (`GD: +2,500,000VND ND: Luong thang 9`)
- Techcombank (`+100,000 VND`)
- VPBank (`PS: -45,000VND ND: The Coffee House`)
- ACB (`-30,000 VND ND: Shopee`)
- TPBank (`+500,000 VND`)
- MoMo (`Nhận 50.000đ từ Nguyễn Văn A`, `Thanh toán 25.000đ Circle K`)
- Generic app / Non-banking notification (returns null or generic transaction)

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/services/bank_notification_parser_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `BankNotificationParser`**
Implement regex and heuristics for:
- Bank detection by package name and keywords
- Amount parser (cleaning `.` and `,` and extracting positive integer)
- Type detection: `credit` (tiền vào) vs `debit` (tiền ra)
- Balance extractor (`SD: ...` or `Số dư: ...`)
- Content/narration extractor (`ND: ...` or `Nội dung: ...`)

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/services/bank_notification_parser_test.dart`
Expected: ALL PASS.

---

### Task 4: Android Native NotificationListenerService & Channels

**Files:**
- Modify: `/home/chinhan/bank_notification_listener/android/app/src/main/AndroidManifest.xml`
- Create: `/home/chinhan/bank_notification_listener/android/app/src/main/kotlin/vn/finance/bank_notification_listener/BankNotificationListenerService.kt`
- Modify: `/home/chinhan/bank_notification_listener/android/app/src/main/kotlin/vn/finance/bank_notification_listener/MainActivity.kt`

**Interfaces:**
- Consumes: Android OS `StatusBarNotification`
- Produces:
  - EventChannel `vn.finance.notification_listener/events`
  - MethodChannel `vn.finance.notification_listener/methods` (`isPermissionGranted`, `openPermissionSettings`)

- [ ] **Step 1: Configure `AndroidManifest.xml`**
Declare `BankNotificationListenerService` with permission `android.permission.BIND_NOTIFICATION_LISTENER_SERVICE` and intent-filter `android.service.notification.NotificationListenerService`.

- [ ] **Step 2: Implement `BankNotificationListenerService.kt`**
Override `onNotificationPosted` to extract package, title, text, subText, timestamp, and forward via a thread-safe callback or companion object event sink.

- [ ] **Step 3: Implement `MainActivity.kt` Channel handlers**
- Handle `isPermissionGranted` by checking `NotificationManagerCompat.getEnabledListenerPackages(context)`.
- Handle `openPermissionSettings` by starting intent `Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS`.
- Register `EventChannel.StreamHandler` to push notifications from the service to Flutter.

---

### Task 5: Dart Notification Bridge & Mock Sample Registry

**Files:**
- Create: `/home/chinhan/bank_notification_listener/lib/services/notification_bridge.dart`
- Create: `/home/chinhan/bank_notification_listener/lib/services/mock_bank_samples.dart`
- Test: `/home/chinhan/bank_notification_listener/test/services/mock_bank_samples_test.dart`

**Interfaces:**
- Produces:
  - `NotificationBridge`: `Stream<RawNotification> get notificationStream`, `Future<bool> isPermissionGranted()`, `Future<void> openSettings()`, `void injectSimulatedNotification(RawNotification notif)`.
  - `MockBankSamples`: curated list of ready-to-test bank notifications.

- [ ] **Step 1: Implement `MockBankSamples` and test**
Provide realistic notification objects for VCB, MB, TCB, VPB, ACB, TPB, BIDV, MoMo. Write test verifying each sample parses successfully.

- [ ] **Step 2: Implement `NotificationBridge`**
Wrap `EventChannel` and `MethodChannel` with fallback stream controller for simulation mode.

---

### Task 6: Realtime Monitor Screen & UI Dashboard

**Files:**
- Create: `/home/chinhan/bank_notification_listener/lib/screens/monitor_screen.dart`
- Create: `/home/chinhan/bank_notification_listener/lib/widgets/transaction_card.dart`
- Create: `/home/chinhan/bank_notification_listener/lib/widgets/simulation_sheet.dart`
- Modify: `/home/chinhan/bank_notification_listener/lib/main.dart`

**Interfaces:**
- Provides rich UI to:
  - Check permission state with 1-click grant button
  - View real-time incoming notification stream
  - Filter "All" vs "Only Banking"
  - View parsed transaction summary badge (+ Credit xanh lá, - Debit đỏ cam)
  - Tap card to view formatted JSON with 1-click copy
  - Floating action button / toolbar to trigger instant bank simulations

- [ ] **Step 1: Implement UI components**
Create clean modern theme with dark/light adaptive colors, `TransactionCard`, `SimulationSheet`.

- [ ] **Step 2: Wire `MonitorScreen` to `NotificationBridge` and `BankNotificationParser`**
Update stream listener to auto-parse incoming events and display in animated list.

---

### Task 7: End-to-End Verification & APK Build Test

**Files:**
- All project files in `/home/chinhan/bank_notification_listener`

- [ ] **Step 1: Run all unit & service tests**
Run: `cd /home/chinhan/bank_notification_listener && flutter test`
Expected: 100% PASS.

- [ ] **Step 2: Run Flutter analyze**
Run: `flutter analyze`
Expected: No issues found!

- [ ] **Step 3: Test build debug APK**
Run: `flutter build apk --debug`
Expected: Build APK succeeds, producing `build/app/outputs/flutter-apk/app-debug.apk`.
