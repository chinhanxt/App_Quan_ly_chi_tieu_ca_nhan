# Specification: Budgeting Feature

## 1. Objective
Implement a Budgeting feature that allows users to proactively set spending limits (budgets) for specific categories on a customized periodic basis (primarily monthly). The system will provide visual UI warnings when spending approaches or exceeds the user-defined limits.

## 2. Core Requirements
- **User-Defined Limits:** Users must be able to manually enter a maximum limit amount (`limitAmount`) for a budget.
- **Category-Specific:** Budgets are tied to specific transaction categories (e.g., "Ăn uống" - Food, "Giải trí" - Entertainment). An option for an "All Categories" overall budget may also be considered.
- **Custom Cycle (Non-Rolling):** Budgets apply to a specific time period (e.g., a specific month like "10 2024"). Excess or deficit amounts do NOT roll over to the next period.
- **UI Warnings:** Visual indicators (progress bars and colors: Green/Yellow/Red) will alert users to their budget status. No strict blocking of transactions will occur.

## 3. Data Architecture (Firestore)

### 3.1. Firestore Structure
Budgets will be stored as a sub-collection under the specific user's document to maintain data isolation and leverage existing Firebase security rules.

**Path:** `users/{userId}/budgets/{budgetId}`

**Document Schema:**
```json
{
  "id": "String (UUID)",
  "categoryName": "String (e.g., 'Ăn uống')",
  "limitAmount": "Number (Integer, representing the user-defined limit)",
  "monthyear": "String (e.g., '10 2024' - matches the format used in transactions for easy querying)",
  "createdAt": "Number (Timestamp in milliseconds)"
}
```
*Note: Using the existing `monthyear` string format simplifies querying and aligns with the current `add_transactions_form.dart` logic.*

### 3.2. Budget Model (`lib/models/budget_model.dart`)
A new Dart model will be created to represent the Budget document.

```dart
class Budget {
  final String id;
  final String categoryName;
  final int limitAmount;
  final String monthyear;
  final DateTime createdAt;

  Budget({
    required this.id,
    required this.categoryName,
    required this.limitAmount,
    required this.monthyear,
    required this.createdAt,
  });

  // factory Budget.fromFirestore(...)
  // Map<String, dynamic> toMap()
}
```

## 4. Service Layer (`lib/services/db.dart`)

The `Db` class will be extended with the following methods:

- `Future<void> addBudget(Budget budget)`: Creates a new budget document.
- `Future<void> updateBudget(Budget budget)`: Updates an existing budget (e.g., modifying the `limitAmount`).
- `Future<void> deleteBudget(String budgetId)`: Removes a budget.
- `Stream<List<Budget>> getBudgets(String monthyear)`: Retrieves a real-time stream of all budgets for a specific period for the current user.

## 5. UI/UX Implementation

### 5.1. Budget Management Screen (`lib/screens/budget_screen.dart`)
- A new screen dedicated to managing budgets.
- **List View:** Displays active budgets for the current month. Each item is a `BudgetProgressCard`.
- **Month Picker:** Allows users to view or set budgets for different months.
- **Add Budget Form:** A modal or embedded form containing:
  - Category Dropdown (populating from the existing `customCategories` or default `AppIcons.homeExpensesCategories`).
  - `TextFormField` (numeric) for the `limitAmount`.

### 5.2. Budget Progress Card (`lib/widgets/budget_progress_card.dart`)
A reusable widget displaying the status of a single budget.

- **Inputs:** `Budget` object, and the total spent amount (`spentAmount`) for that category in the given `monthyear`.
- **Calculations:**
  - `percentage = (spentAmount / limitAmount) * 100`
  - Remaining amount: `limitAmount - spentAmount`
- **UI Logic (Color-coded Warning System):**
  - **Green/Blue:** `percentage < 80%` (Safe)
  - **Yellow/Orange:** `80% <= percentage < 100%` (Warning - Approaching limit)
  - **Red:** `percentage >= 100%` (Alert - Over budget)
- **Visuals:** A linear progress indicator and text showing "Spent X / Limit Y".

### 5.3. Integration Points
- **Dashboard (`lib/screens/dashboard.dart`):** Add the `BudgetScreen` to the `pageViewList` and a new icon to the `Navbar` to make it a primary navigation option.
- **Home Screen (`lib/screens/home_screen.dart`):** (Optional but recommended) Display a summarized "Overall Budget" or the top 3 closest-to-limit budgets directly on the home screen for immediate visibility.
- **Transaction Form (`lib/widgets/add_transactions_form.dart`):** When adding a new debit transaction, optionally calculate if this new amount will cause a budget to exceed 100% and show a soft, non-blocking warning text before submission.

## 6. Logic & Calculation

The core challenge is accurately calculating the `spentAmount` to feed into the `BudgetProgressCard`.

**Approach:**
1. The `BudgetScreen` listens to the `Stream<List<Budget>>` for the selected month.
2. It simultaneously needs to listen to or fetch `Transactions` for that same month (using `ReportService` logic or direct `Db` queries on the `monthyear` field where `type == 'debit'`).
3. For each `Budget`, filter the transactions by `categoryName` and sum the `amount`.
4. This combined data is passed to the UI widgets.

*(Note: To optimize performance, the aggregation can be done efficiently in Dart using `fold` and `where`, similar to existing logic in `ReportService.analyzeByCategory`, rather than complex backend queries.)*