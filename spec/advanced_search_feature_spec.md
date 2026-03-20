# Specification: Advanced Search & Filtering Feature

## 1. Objective
Implement a high-performance, real-time search and filtering screen for transactions. The user must be able to instantly find specific transactions based on a combination of text (title/notes), date range, amount range, transaction type (income/expense), and category.

## 2. Core Requirements
- **Dedicated Screen:** A new screen (`SearchScreen`) accessible via a search icon on the `TransactionScreen` AppBar.
- **Real-time Results:** Results must update instantly as the user types or adjusts filters (no "Search" button required).
- **Comprehensive Filters:**
  - Text Search (Case-insensitive matching on transaction `title`).
  - Transaction Type (All, Credit/Income, Debit/Expense).
  - Category (Dropdown or multi-select chips).
  - Date Range (Start Date to End Date).
  - Amount Range (Min Amount to Max Amount).
- **Client-Side Filtering:** Due to Firestore's limitations with multiple inequality queries and full-text search, the primary filtering engine will be implemented in Dart (Client-Side) on a fetched dataset.

## 3. Architecture & Data Flow

### 3.1 Data Fetching Strategy
- **Stream/Future:** To balance real-time updates and Firestore read costs, the `SearchScreen` will fetch transactions.
- **Scope:** Fetch all transactions for the current user. *Optimization Note: If the user has thousands of transactions, an initial query limiting by a generous date range (e.g., last 12 months) might be necessary later, but for typical personal use, loading all into a local Dart `List` is most efficient for instant multi-field filtering.*
- **Model:** Utilize the existing `TransactionDetail` model (`lib/models/report_models.dart`) for type-safe filtering.

### 3.2 Filtering Engine (Dart)
The filtering logic will sequentially apply active filters to the `List<TransactionDetail>`:
1.  **Type Filter:** `tx.type == selectedType`
2.  **Category Filter:** `tx.category == selectedCategory`
3.  **Date Filter:** `tx.date.isAfter(startDate)` AND `tx.date.isBefore(endDate)`
4.  **Amount Filter:** `tx.amount >= minAmount` AND `tx.amount <= maxAmount`
5.  **Text Filter:** `tx.title.toLowerCase().contains(searchQuery.toLowerCase())`

## 4. UI/UX Implementation

### 4.1 Search Screen (`lib/screens/search_screen.dart`)
- **AppBar:** Contains a `TextField` for the primary text search query, auto-focused upon entry.
- **Filter Bar (Horizontal Scroll):** A row of `FilterChip` or `ActionChip` widgets immediately below the AppBar:
  - "Loại: Tất cả / Thu / Chi"
  - "Thời gian: Bất kỳ / Chọn ngày..." (Opens `DateRangePickerDialog`)
  - "Danh mục: Tất cả / Chọn..." (Opens a BottomSheet or Dialog with categories)
  - "Số tiền: Bất kỳ / Nhập..." (Opens a Dialog with Min/Max text fields)
- **Active Filters Wrap:** A visual representation of currently applied filters (e.g., "Chi", "Ăn uống", "Từ 1tr - 5tr") with 'x' buttons to quickly remove them.
- **Results Body:**
  - **Empty State (Pre-search):** Icon/Text suggesting "Bắt đầu gõ để tìm kiếm..." (Start typing to search...).
  - **No Results State:** Icon/Text indicating "Không tìm thấy giao dịch phù hợp" (No matching transactions found).
  - **Results List:** A `ListView.builder` displaying the filtered `TransactionDetail` items using the existing `TransactionCard` UI component (or a simplified `ListTile` version if `TransactionCard` is too large).

### 4.2 Integration Point
- **`lib/screens/transaction_screen.dart`:** Add an `IconButton(icon: Icon(Icons.search))` to the `AppBar` `actions` list. `onPressed` will execute `Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()))`.

## 5. Technical Details & Considerations
- **Performance:** For huge datasets, `ListView.builder` ensures UI performance during scrolling.
- **Debouncing:** If fetching data directly from Firestore based on text input (not recommended here, but if needed), a debounce mechanism (e.g., 300ms delay) on the text input is crucial to prevent excessive read requests. However, since we are filtering client-side, debouncing the UI update is optional but good practice for extremely large lists.
- **Currency Formatting:** Utilize `intl` (`NumberFormat.currency`) for displaying amount ranges in the filter chips and dialogs consistently with the rest of the app.
- **Category Source:** Load categories dynamically from `customCategories` in the user document + `AppIcons().defaultCategories` to populate the Category filter options.