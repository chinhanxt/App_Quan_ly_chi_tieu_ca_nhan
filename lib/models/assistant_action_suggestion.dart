enum AssistantActionType {
  openHome,
  openBudget,
  openSavings,
  openReport,
  openSettings,
  openCategoryManagement,
  openNotifications,
  openSearch,
  openManualTransaction,
  switchToTransaction,
  openAddTransaction,
}

class AssistantActionSuggestion {
  const AssistantActionSuggestion({
    required this.id,
    required this.label,
    required this.type,
    this.payload,
  });

  final String id;
  final String label;
  final AssistantActionType type;
  final String? payload;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'type': _typeToWireName(type),
      'payload': payload,
    };
  }

  factory AssistantActionSuggestion.fromJson(Map<String, dynamic> json) {
    final typeName = json['type']?.toString() ?? '';
    return AssistantActionSuggestion(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: _typeFromWireName(typeName),
      payload: json['payload']?.toString(),
    );
  }

  static AssistantActionType _typeFromWireName(String value) {
    switch (value.trim()) {
      case 'open_home':
      case 'openHome':
        return AssistantActionType.openHome;
      case 'open_budget':
      case 'openBudget':
        return AssistantActionType.openBudget;
      case 'open_savings':
      case 'openSavings':
        return AssistantActionType.openSavings;
      case 'open_report':
      case 'openReport':
        return AssistantActionType.openReport;
      case 'open_settings':
      case 'openSettings':
        return AssistantActionType.openSettings;
      case 'open_category_management':
      case 'openCategoryManagement':
      case 'open_category':
        return AssistantActionType.openCategoryManagement;
      case 'open_notifications':
      case 'openNotifications':
      case 'open_notification':
        return AssistantActionType.openNotifications;
      case 'open_search':
      case 'openSearch':
        return AssistantActionType.openSearch;
      case 'open_manual_transaction':
      case 'openManualTransaction':
      case 'open_add_transaction_manual':
        return AssistantActionType.openManualTransaction;
      case 'switch_to_transaction':
      case 'switchToTransaction':
        return AssistantActionType.switchToTransaction;
      case 'open_add_transaction':
      case 'openAddTransaction':
        return AssistantActionType.openAddTransaction;
      default:
        return AssistantActionType.switchToTransaction;
    }
  }

  static String _typeToWireName(AssistantActionType type) {
    switch (type) {
      case AssistantActionType.openHome:
        return 'open_home';
      case AssistantActionType.openBudget:
        return 'open_budget';
      case AssistantActionType.openSavings:
        return 'open_savings';
      case AssistantActionType.openReport:
        return 'open_report';
      case AssistantActionType.openSettings:
        return 'open_settings';
      case AssistantActionType.openCategoryManagement:
        return 'open_category_management';
      case AssistantActionType.openNotifications:
        return 'open_notifications';
      case AssistantActionType.openSearch:
        return 'open_search';
      case AssistantActionType.openManualTransaction:
        return 'open_manual_transaction';
      case AssistantActionType.switchToTransaction:
        return 'switch_to_transaction';
      case AssistantActionType.openAddTransaction:
        return 'open_add_transaction';
    }
  }
}
