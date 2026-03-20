import 'dart:convert';
import 'dart:ui';

import 'package:app/models/ai_chat_message.dart';
import 'package:app/models/quick_template.dart';
import 'package:app/services/ai_service.dart';
import 'package:app/utils/icon_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AIInputScreen extends StatefulWidget {
  const AIInputScreen({super.key});

  @override
  State<AIInputScreen> createState() => _AIInputScreenState();
}

class _AIInputScreenState extends State<AIInputScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accentBlue = Color(0xFF67A6FF);
  static const Color _accentCyan = Color(0xFF5DEBFF);
  static const Color _accentViolet = Color(0xFF8A72FF);
  static const Color _accentPink = Color(0xFFD77DFF);
  static const Color _surfaceInk = Color(0xFFF5F7FF);
  static const List<Color> _suggestionAccents = <Color>[
    _accentBlue,
    _accentCyan,
    _accentViolet,
    _accentPink,
    Color(0xFF7EE787),
  ];

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currencyFormat = NumberFormat.decimalPattern('vi_VN');
  final aiService = AIService();
  final appIcons = AppIcons();
  final Uuid _uuid = const Uuid();
  final List<AIChatMessage> _messages = <AIChatMessage>[];
  final List<QuickTemplate> _quickTemplates = <QuickTemplate>[];
  final Set<String> _savingMessageIds = <String>{};

  late AnimationController _pulseController;

  bool _isProcessing = false;
  bool _isRestoringHistory = true;
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _restoreChatHistory();
    _loadQuickTemplates();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool _hasSuspiciousEncoding(String text) {
    return RegExp(r'(Ã.|Ä.|Æ.|áº|á»|â€)').hasMatch(text);
  }

  String _repairLegacyText(String text) {
    if (text.isEmpty || !_hasSuspiciousEncoding(text)) {
      return text;
    }

    try {
      final repaired = utf8.decode(latin1.encode(text));
      return _hasSuspiciousEncoding(repaired) ? text : repaired;
    } catch (_) {
      return text;
    }
  }

  Map<String, dynamic> _repairLegacyTransaction(Map<String, dynamic> tx) {
    final repaired = Map<String, dynamic>.from(tx);
    for (final entry in repaired.entries.toList()) {
      final value = entry.value;
      if (value is String) {
        repaired[entry.key] = _repairLegacyText(value);
      }
    }
    return repaired;
  }

  AIChatMessage _repairLegacyMessage(AIChatMessage message) {
    return message.copyWith(
      text: _repairLegacyText(message.text),
      transactions: message.transactions.map(_repairLegacyTransaction).toList(),
    );
  }

  Future<void> _restoreChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey());
    var didRepairHistory = false;

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final restored = decoded.whereType<Map>().map<AIChatMessage>((item) {
            final message = AIChatMessage.fromJson(
              Map<String, dynamic>.from(item),
            );
            final repaired = _repairLegacyMessage(message);
            if (!didRepairHistory &&
                jsonEncode(message.toJson()) != jsonEncode(repaired.toJson())) {
              didRepairHistory = true;
            }
            return repaired;
          }).toList();

          if (mounted) {
            setState(() {
              _messages
                ..clear()
                ..addAll(restored);
            });
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isRestoringHistory = false;
      });
    }

    _scrollToBottom(animated: false);

    if (didRepairHistory && _messages.isNotEmpty) {
      await _persistChatHistory();
    }
  }

  Future<void> _persistChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey(),
      jsonEncode(_messages.map((message) => message.toJson()).toList()),
    );
  }

  String _storageKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'ai_chat_history_$uid';
  }

  DocumentReference<Map<String, dynamic>>? _userDocRef() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }

  List<QuickTemplate> _defaultQuickTemplates() {
    return <QuickTemplate>[
      const QuickTemplate(
        id: 'breakfast-30k',
        label: 'Ăn sáng 30k',
        title: 'Ăn sáng',
        amount: 30000,
        type: 'debit',
        category: 'Ăn uống',
        note: 'Mẫu chọn nhanh',
        iconName: 'utensils',
      ),
      const QuickTemplate(
        id: 'salary-15m',
        label: 'Lương 15 triệu',
        title: 'Lương về',
        amount: 15000000,
        type: 'credit',
        category: 'Lương',
        note: 'Mẫu chọn nhanh',
        iconName: 'moneyBillWave',
      ),
      const QuickTemplate(
        id: 'gas-50k',
        label: 'Đổ xăng 50k',
        title: 'Đổ xăng',
        amount: 50000,
        type: 'debit',
        category: 'Di chuyển',
        note: 'Mẫu chọn nhanh',
        iconName: 'car',
      ),
      const QuickTemplate(
        id: 'shopee-200k',
        label: 'Shopee 200k',
        title: 'Mua sắm Shopee',
        amount: 200000,
        type: 'debit',
        category: 'Mua sắm',
        note: 'Mẫu chọn nhanh',
        iconName: 'cartShopping',
      ),
      const QuickTemplate(
        id: 'rent-3m',
        label: 'Tiền nhà 3tr',
        title: 'Tiền nhà',
        amount: 3000000,
        type: 'debit',
        category: 'Nhà',
        note: 'Mẫu chọn nhanh',
        iconName: 'house',
      ),
    ];
  }

  bool _isKnownCategory(String category, {Map<String, dynamic>? userData}) {
    final normalized = category.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    final categoryPools = <Map<String, dynamic>>[
      ...appIcons.defaultCategories,
      ...appIcons.suggestedCategories,
      ...((userData?['customCategories'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))),
    ];

    return categoryPools.any(
      (item) => item['name']?.toString().trim().toLowerCase() == normalized,
    );
  }

  String _resolveTemplateIconName(
    String category, {
    required String type,
    Map<String, dynamic>? userData,
  }) {
    final normalized = category.trim().toLowerCase();
    final categoryPools = <Map<String, dynamic>>[
      ...appIcons.defaultCategories,
      ...appIcons.suggestedCategories,
      ...((userData?['customCategories'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))),
    ];

    for (final item in categoryPools) {
      if (item['name']?.toString().trim().toLowerCase() == normalized) {
        return item['iconName']?.toString() ??
            (type == 'credit' ? 'moneyBillWave' : 'cartShopping');
      }
    }

    return type == 'credit' ? 'moneyBillWave' : 'cartShopping';
  }

  List<QuickTemplate> _normalizeQuickTemplates(dynamic rawTemplates) {
    if (rawTemplates is! List) return const <QuickTemplate>[];

    return rawTemplates
        .whereType<Map>()
        .map<QuickTemplate>((item) {
          final mapped = Map<String, dynamic>.from(item);
          return QuickTemplate.fromJson(mapped);
        })
        .where((template) {
          return template.label.trim().isNotEmpty &&
              template.title.trim().isNotEmpty &&
              template.amount > 0 &&
              template.category.trim().isNotEmpty;
        })
        .toList();
  }

  Future<void> _loadQuickTemplates() async {
    final defaults = _defaultQuickTemplates();
    final userDocRef = _userDocRef();

    if (userDocRef == null) {
      if (!mounted) return;
      setState(() {
        _quickTemplates
          ..clear()
          ..addAll(defaults);
      });
      return;
    }

    try {
      final snapshot = await userDocRef.get();
      final data = snapshot.data();
      final hasField = data?.containsKey('quickTemplates') ?? false;
      final templates = _normalizeQuickTemplates(data?['quickTemplates']);

      if (!mounted) return;

      if (!hasField) {
        await userDocRef.set({
          'quickTemplates': defaults.map((item) => item.toJson()).toList(),
        }, SetOptions(merge: true));
        setState(() {
          _quickTemplates
            ..clear()
            ..addAll(defaults);
        });
        return;
      }

      setState(() {
        _quickTemplates
          ..clear()
          ..addAll(templates);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _quickTemplates
          ..clear()
          ..addAll(defaults);
      });
    }
  }

  Future<bool> _saveQuickTemplates(List<QuickTemplate> templates) async {
    try {
      final userDocRef = _userDocRef();
      if (userDocRef != null) {
        await userDocRef.set({
          'quickTemplates': templates.map((item) => item.toJson()).toList(),
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      }

      if (!mounted) return true;
      setState(() {
        _quickTemplates
          ..clear()
          ..addAll(templates);
      });
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa lưu được mục Chọn nhanh lên tài khoản. Bạn thử lại giúp mình nhé.',
            ),
          ),
        );
      }
      return false;
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final target = _scrollController.position.maxScrollExtent + 140;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _submitInput({String? preset}) async {
    final text = (preset ?? _inputController.text).trim();
    if (text.isEmpty || _isProcessing) return;

    final userMessage = AIChatMessage(
      id: _uuid.v4(),
      sender: AIChatSender.user,
      text: text,
      timestamp: DateTime.now(),
      status: 'user',
    );

    _inputController.clear();

    setState(() {
      _messages.add(userMessage);
      _isProcessing = true;
    });
    _persistChatHistory();
    _scrollToBottom();

    try {
      final result = await aiService.processInput(text);
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _messages.add(_buildAiMessage(result));
      });
      _persistChatHistory();
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _messages.add(
          AIChatMessage(
            id: _uuid.v4(),
            sender: AIChatSender.ai,
            text:
                "Kết nối AI đang hơi chập chờn. Bạn thử gửi lại giúp mình nhé!",
            timestamp: DateTime.now(),
            status: 'error',
          ),
        );
      });
      _persistChatHistory();
      _scrollToBottom();
    }
  }

  Future<void> _applyQuickTemplate(QuickTemplate template) async {
    if (_isProcessing) return;

    final now = DateTime.now();
    Map<String, dynamic>? userData;
    final userDocRef = _userDocRef();

    try {
      if (userDocRef != null) {
        final snapshot = await userDocRef.get();
        userData = snapshot.data();
      }
    } catch (_) {
      userData = null;
    }

    final isKnownCategory = _isKnownCategory(
      template.category,
      userData: userData,
    );
    final iconName = template.iconName.trim().isNotEmpty
        ? template.iconName
        : _resolveTemplateIconName(
            template.category,
            type: template.type,
            userData: userData,
          );

    final userMessage = AIChatMessage(
      id: _uuid.v4(),
      sender: AIChatSender.user,
      text: "Chọn nhanh: ${template.label}",
      timestamp: now,
      status: 'user',
    );

    final aiMessage = AIChatMessage(
      id: _uuid.v4(),
      sender: AIChatSender.ai,
      text:
          "Mình đã dựng sẵn card từ mục Chọn nhanh. Bạn kiểm tra lại rồi bấm lưu là xong.",
      timestamp: now,
      status: 'success',
      transactions: <Map<String, dynamic>>[
        <String, dynamic>{
          'title': template.title,
          'amount': template.amount,
          'type': template.type,
          'category': template.category,
          'note': template.note,
          'date': DateFormat('dd/MM/yyyy').format(now),
          'time': DateFormat('HH:mm').format(now),
          'dateTime': DateFormat('dd/MM/yyyy HH:mm').format(now),
          'isNewCategory': !isKnownCategory,
          'confirmCreateCategory': !isKnownCategory,
          'suggestedIcon': iconName,
        },
      ],
    );

    if (!mounted) return;
    setState(() {
      _messages
        ..add(userMessage)
        ..add(aiMessage);
    });
    await _persistChatHistory();
    _scrollToBottom();
  }

  Future<QuickTemplate?> _showQuickTemplateForm({
    QuickTemplate? initialTemplate,
  }) async {
    Map<String, dynamic>? userData;
    try {
      final userDocRef = _userDocRef();
      if (userDocRef != null) {
        final snapshot = await userDocRef.get();
        userData = snapshot.data();
      }
    } catch (_) {
      userData = null;
    }

    if (!mounted) return null;

    final labelController = TextEditingController(
      text: initialTemplate?.label ?? '',
    );
    final titleController = TextEditingController(
      text: initialTemplate?.title ?? '',
    );
    final amountController = TextEditingController(
      text: initialTemplate?.amount.toString() ?? '',
    );
    final categoryController = TextEditingController(
      text: initialTemplate?.category ?? '',
    );
    final noteController = TextEditingController(
      text: initialTemplate?.note ?? '',
    );
    var selectedType = initialTemplate?.type ?? 'debit';

    final result = await showModalBottomSheet<QuickTemplate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 24,
              ),
              child: _buildGlassSurface(
                borderRadius: BorderRadius.circular(28),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                gradient: _glassGradient(
                  accent: selectedType == 'credit'
                      ? const Color(0xFF7EE787)
                      : _accentViolet,
                  baseAlpha: 0.2,
                  accentAlpha: 0.16,
                ),
                borderColor: Colors.white.withValues(alpha: 0.12),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              initialTemplate == null
                                  ? 'Thêm mục Chọn nhanh'
                                  : 'Sửa mục Chọn nhanh',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mục này sẽ tạo card giao dịch trực tiếp, không cần AI phân tích lại.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildQuickTemplateField(
                        controller: labelController,
                        label: 'Tên ô Chọn nhanh',
                        hint: 'Ví dụ: Cafe sáng',
                      ),
                      const SizedBox(height: 12),
                      _buildQuickTemplateField(
                        controller: titleController,
                        label: 'Tên giao dịch',
                        hint: 'Ví dụ: Uống cafe',
                      ),
                      const SizedBox(height: 12),
                      _buildQuickTemplateField(
                        controller: amountController,
                        label: 'Số tiền',
                        hint: 'Ví dụ: 30000',
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loại giao dịch',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.74),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTemplateTypeOption(
                              label: 'Chi',
                              value: 'debit',
                              selectedType: selectedType,
                              onTap: () => setSheetState(() {
                                selectedType = 'debit';
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTemplateTypeOption(
                              label: 'Thu',
                              value: 'credit',
                              selectedType: selectedType,
                              onTap: () => setSheetState(() {
                                selectedType = 'credit';
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildQuickTemplateField(
                        controller: categoryController,
                        label: 'Danh mục',
                        hint: 'Ví dụ: Ăn uống',
                      ),
                      const SizedBox(height: 12),
                      _buildQuickTemplateField(
                        controller: noteController,
                        label: 'Ghi chú',
                        hint: 'Không bắt buộc',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            final label = labelController.text.trim();
                            final title = titleController.text.trim();
                            final amount =
                                int.tryParse(amountController.text) ?? 0;
                            final category = categoryController.text.trim();
                            final note = noteController.text.trim();

                            if (label.isEmpty ||
                                title.isEmpty ||
                                category.isEmpty ||
                                amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Điền tên ô, tên giao dịch, số tiền và danh mục trước nhé.',
                                  ),
                                ),
                              );
                              return;
                            }

                            Navigator.of(context).pop(
                              QuickTemplate(
                                id: initialTemplate?.id ?? _uuid.v4(),
                                label: label,
                                title: title,
                                amount: amount,
                                type: selectedType,
                                category: category,
                                note: note,
                                iconName: _resolveTemplateIconName(
                                  category,
                                  type: selectedType,
                                  userData: userData,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1A1F4B),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            initialTemplate == null
                                ? 'Thêm mẫu'
                                : 'Lưu thay đổi',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    labelController.dispose();
    titleController.dispose();
    amountController.dispose();
    categoryController.dispose();
    noteController.dispose();

    return result;
  }

  Future<void> _openQuickTemplateManager() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> addTemplate() async {
              final created = await _showQuickTemplateForm();
              if (created == null) return;

              final didSave = await _saveQuickTemplates(<QuickTemplate>[
                ..._quickTemplates,
                created,
              ]);
              if (didSave) {
                setSheetState(() {});
              }
            }

            Future<void> editTemplate(int index) async {
              final updated = await _showQuickTemplateForm(
                initialTemplate: _quickTemplates[index],
              );
              if (updated == null) return;

              final next = <QuickTemplate>[..._quickTemplates];
              next[index] = updated;
              final didSave = await _saveQuickTemplates(next);
              if (didSave) {
                setSheetState(() {});
              }
            }

            Future<void> deleteTemplate(int index) async {
              final shouldDelete = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Xóa mục Chọn nhanh'),
                    content: Text(
                      'Bạn muốn xóa "${_quickTemplates[index].label}" khỏi danh sách Chọn nhanh?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Xóa'),
                      ),
                    ],
                  );
                },
              );

              if (shouldDelete != true) return;

              final next = <QuickTemplate>[..._quickTemplates]..removeAt(index);
              final didSave = await _saveQuickTemplates(next);
              if (didSave) {
                setSheetState(() {});
              }
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
              child: _buildGlassSurface(
                borderRadius: BorderRadius.circular(30),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                gradient: _glassGradient(
                  accent: _accentPink,
                  baseAlpha: 0.18,
                  accentAlpha: 0.16,
                ),
                borderColor: Colors.white.withValues(alpha: 0.12),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Quản lý Chọn nhanh',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Thêm, sửa hoặc xóa các mẫu giao dịch để dùng khi AI không xử lý đúng ý bạn.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_quickTemplates.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Text(
                            'Chưa có mục Chọn nhanh nào. Bạn thêm mẫu đầu tiên để dùng như lối tắt cho giao dịch quen thuộc.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              height: 1.4,
                            ),
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 360),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _quickTemplates.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _quickTemplates[index];
                              final accent = item.isCredit
                                  ? const Color(0xFF7EE787)
                                  : _suggestionAccents[index %
                                        _suggestionAccents.length];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.16),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        appIcons.getIconData(item.iconName),
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.label,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.title} • ${item.category} • ${currencyFormat.format(item.amount)} đ',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.68,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => editTemplate(index),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.white,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => deleteTemplate(index),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFFFB7B7),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: addTemplate,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text(
                            'Thêm mục Chọn nhanh',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1A1F4B),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  AIChatMessage _buildAiMessage(Map<String, dynamic> result) {
    final transactions = _normalizeTransactions(result['transactions']);
    final status =
        result['status']?.toString() ??
        (result['success'] == true
            ? 'success'
            : result['success'] == false
            ? 'error'
            : 'clarification');

    final text = result['message']?.toString().trim().isNotEmpty == true
        ? result['message'].toString()
        : result['success'] == true
        ? transactions.length > 1
              ? "Mình đã tách được ${transactions.length} giao dịch. Bạn xem lại rồi bấm xác nhận để lưu nhé!"
              : "Mình đã bóc tách được 1 giao dịch. Bạn xem lại rồi bấm xác nhận để lưu nhé!"
        : status == 'error'
        ? "AI đang gặp trục trặc nhỏ. Bạn thử lại giúp mình sau nhé!"
        : "Mình cần thêm một chút thông tin để ghi đúng giao dịch cho bạn.";

    return AIChatMessage(
      id: _uuid.v4(),
      sender: AIChatSender.ai,
      text: text,
      timestamp: DateTime.now(),
      transactions: transactions,
      status: status,
    );
  }

  List<Map<String, dynamic>> _normalizeTransactions(dynamic rawTransactions) {
    if (rawTransactions is! List) return const <Map<String, dynamic>>[];
    return rawTransactions.whereType<Map>().map<Map<String, dynamic>>((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  void _updateTransactionField({
    required String messageId,
    required int transactionIndex,
    required String field,
    required dynamic value,
  }) {
    final messageIndex = _messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (messageIndex == -1) return;

    final message = _messages[messageIndex];
    final updatedTransactions = message.transactions
        .map((transaction) => Map<String, dynamic>.from(transaction))
        .toList();

    if (transactionIndex < 0 ||
        transactionIndex >= updatedTransactions.length) {
      return;
    }

    updatedTransactions[transactionIndex][field] = value;

    setState(() {
      _messages[messageIndex] = message.copyWith(
        transactions: updatedTransactions,
      );
    });
    _persistChatHistory();
  }

  Future<void> _saveTransactionsForMessage(AIChatMessage message) async {
    if (message.transactions.isEmpty || message.isSaved) return;
    if (_savingMessageIds.contains(message.id)) return;

    setState(() {
      _savingMessageIds.add(message.id);
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Vui lòng đăng nhập lại để lưu giao dịch.");
      }

      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userDocRef);
        if (!userSnapshot.exists) {
          throw Exception("Không tìm thấy dữ liệu người dùng.");
        }

        int remainingAmount = userSnapshot['remainingAmount'];
        int totalCredit = userSnapshot['totalCredit'];
        int totalDebit = userSnapshot['totalDebit'];
        List<dynamic> customCategories = List.from(
          userSnapshot.data()?['customCategories'] ?? [],
        );

        for (final tx in message.transactions) {
          final int amount = tx['amount'];
          final String type = tx['type'];
          final String id = _uuid.v4();

          if (tx['isNewCategory'] == true &&
              (tx['confirmCreateCategory'] ?? true)) {
            final exists = customCategories.any(
              (category) => category['name'] == tx['category'],
            );
            if (!exists) {
              customCategories.add({
                'name': tx['category'],
                'iconName': tx['suggestedIcon'],
              });
            }
          }

          if (type == 'credit') {
            remainingAmount += amount;
            totalCredit += amount;
          } else {
            remainingAmount -= amount;
            totalDebit -= amount;
          }

          DateTime txDate;
          try {
            final dateTimeText = tx['dateTime']?.toString();
            if (dateTimeText != null && dateTimeText.isNotEmpty) {
              txDate = DateFormat('dd/MM/yyyy HH:mm').parseStrict(dateTimeText);
            } else {
              txDate = DateFormat('dd/MM/yyyy').parse(tx['date']);
            }
          } catch (_) {
            txDate = DateTime.now();
          }

          transaction.set(userDocRef.collection("transactions").doc(id), {
            "id": id,
            "title": tx['title'],
            "amount": amount,
            "type": type,
            "timestamp": txDate.millisecondsSinceEpoch,
            "totalCredit": totalCredit,
            "totalDebit": totalDebit,
            "remainingAmount": remainingAmount,
            "monthyear": "${txDate.month} ${txDate.year}",
            "category": tx['category'],
            "note": tx['note'],
          });
        }

        transaction.update(userDocRef, {
          "remainingAmount": remainingAmount,
          "totalCredit": totalCredit,
          "totalDebit": totalDebit,
          "customCategories": customCategories,
          "updatedAt": DateTime.now().millisecondsSinceEpoch,
        });
      });

      final messageIndex = _messages.indexWhere(
        (item) => item.id == message.id,
      );
      if (messageIndex != -1) {
        setState(() {
          _messages[messageIndex] = _messages[messageIndex].copyWith(
            isSaved: true,
          );
          _messages.add(
            AIChatMessage(
              id: _uuid.v4(),
              sender: AIChatSender.ai,
              text:
                  "Mình đã lưu ${message.transactions.length} giao dịch cho bạn rồi. Có gì bạn cứ nhắn tiếp nhé!",
              timestamp: DateTime.now(),
              status: 'success',
            ),
          );
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Giao dịch AI đã được lưu thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            AIChatMessage(
              id: _uuid.v4(),
              sender: AIChatSender.ai,
              text: "Mình chưa lưu được giao dịch: $e",
              timestamp: DateTime.now(),
              status: 'error',
            ),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi hệ thống khi lưu giao dịch. Thử lại sau!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingMessageIds.remove(message.id);
        });
      }
      _persistChatHistory();
      _scrollToBottom();
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final sameDay =
        now.year == timestamp.year &&
        now.month == timestamp.month &&
        now.day == timestamp.day;

    return sameDay
        ? DateFormat('HH:mm').format(timestamp)
        : DateFormat('HH:mm - dd/MM').format(timestamp);
  }

  Color _statusTint(String status) {
    switch (status) {
      case 'clarification':
        return const Color(0xFFFFB020);
      case 'error':
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF5B8CFF);
    }
  }

  LinearGradient _glassGradient({
    Color accent = _accentBlue,
    double baseAlpha = 0.16,
    double accentAlpha = 0.18,
  }) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: baseAlpha),
        accent.withValues(alpha: accentAlpha),
        const Color(0xFF140A35).withValues(alpha: 0.22),
      ],
      stops: const [0, 0.45, 1],
    );
  }

  Widget _buildGlassSurface({
    required Widget child,
    required BorderRadius borderRadius,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    Gradient? gradient,
    Color? color,
    Color borderColor = const Color(0x26FFFFFF),
    double blur = 18,
    List<BoxShadow>? boxShadow,
  }) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: gradient == null
                ? (color ?? Colors.white.withValues(alpha: 0.08))
                : null,
            gradient: gradient,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor),
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildQuickTemplateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.74),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateTypeOption({
    required String label,
    required String value,
    required String selectedType,
    required VoidCallback onTap,
  }) {
    final isSelected = value == selectedType;
    final accent = value == 'credit'
        ? const Color(0xFF7EE787)
        : const Color(0xFF8A72FF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? accent.withValues(alpha: 0.34)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: isSelected ? 1 : 0.76),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.08).animate(_pulseController),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.purple[400]!],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.35),
                          blurRadius: 26,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Hero(
                      tag: 'ai_button',
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Trợ lý AI",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isProcessing
                            ? "Đang suy nghĩ..."
                            : "Nhập thu chi tự nhiên, AI sẽ tự động bóc tách.",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4ADE80),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "Online",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.purple[400]!],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.28),
                    blurRadius: 28,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.forum_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Sẵn sàng hỗ trợ!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Hãy nhắn nội dung như: 'Ăn sáng 30k' hoặc 'Lương về 10tr'...",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: FadeTransition(
        opacity: Tween(begin: 0.45, end: 1.0).animate(_pulseController),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return Container(
                margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85 - (index * 0.18)),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AIChatMessage message) {
    final isUser = message.sender == AIChatSender.user;
    final tint = _statusTint(message.status);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            _buildGlassSurface(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(22),
                topRight: const Radius.circular(22),
                bottomLeft: Radius.circular(isUser ? 22 : 8),
                bottomRight: Radius.circular(isUser ? 8 : 22),
              ),
              gradient: isUser
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1C84FF),
                        Color(0xFF3B61F3),
                        Color(0xFF533DCA),
                      ],
                    )
                  : _glassGradient(
                      accent: tint == const Color(0xFF5B8CFF)
                          ? _accentViolet
                          : tint,
                      baseAlpha: 0.14,
                      accentAlpha: 0.2,
                    ),
              borderColor: isUser
                  ? Colors.white.withValues(alpha: 0.12)
                  : tint.withValues(alpha: 0.18),
              boxShadow: [
                BoxShadow(
                  color: (isUser ? _accentBlue : tint).withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: tint.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        message.status == 'clarification'
                            ? "Cần làm rõ"
                            : message.status == 'error'
                            ? "Có lỗi nhỏ"
                            : "AI trả lời",
                        style: TextStyle(
                          color: tint,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Text(
                    _repairLegacyText(message.text),
                    style: TextStyle(
                      color: _surfaceInk,
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 6, right: 6),
              child: Text(
                _formatMessageTime(message.timestamp),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.52),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    AIChatMessage message,
    int index,
    Map<String, dynamic> tx,
  ) {
    final bool isNewCat = tx['isNewCategory'] == true;
    final bool isCredit = tx['type'] == 'credit';
    final accent = isCredit ? const Color(0xFF7EE787) : const Color(0xFFFF8A8A);
    final amountColor = isCredit
        ? const Color(0xFFB8FFD0)
        : const Color(0xFFFFB7B7);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: _buildGlassSurface(
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(24),
        gradient: _glassGradient(
          accent: accent,
          baseAlpha: 0.2,
          accentAlpha: 0.14,
        ),
        borderColor: accent.withValues(alpha: 0.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _repairLegacyText(
                          tx['title']?.toString() ?? "Không có tiêu đề",
                        ),
                        style: const TextStyle(
                          color: _surfaceInk,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _accentCyan.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  appIcons.getIconData(
                                    tx['suggestedIcon'] ?? "cartShopping",
                                  ),
                                  size: 14,
                                  color: _accentCyan,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _repairLegacyText(
                                    tx['category']?.toString() ?? "Khác",
                                  ),
                                  style: const TextStyle(
                                    color: _surfaceInk,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isNewCat)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFB020,
                                ).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(
                                    0xFFFFD27A,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Text(
                                "Danh mục mới",
                                style: TextStyle(
                                  color: Color(0xFFFFE4A3),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${isCredit ? '+' : '-'}${currencyFormat.format(tx['amount'])} đ",
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            if (tx['note'] != null && tx['note'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  "Ghi chú: ${_repairLegacyText(tx['note'].toString())}",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            if (tx['dateTime'] != null && tx['dateTime'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Thời gian: ${_repairLegacyText(tx['dateTime'].toString())}",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.64),
                    fontSize: 13,
                  ),
                ),
              ),
            if (isNewCat)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Tạo danh mục mới?",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Switch(
                        value: tx['confirmCreateCategory'] ?? true,
                        onChanged: message.isSaved
                            ? null
                            : (value) {
                                _updateTransactionField(
                                  messageId: message.id,
                                  transactionIndex: index,
                                  field: 'confirmCreateCategory',
                                  value: value,
                                );
                              },
                        activeThumbColor: _accentBlue,
                        activeTrackColor: _accentCyan.withValues(alpha: 0.35),
                        inactiveThumbColor: Colors.white.withValues(alpha: 0.9),
                        inactiveTrackColor: Colors.white.withValues(
                          alpha: 0.16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiMessageContent(AIChatMessage message) {
    final isSaving = _savingMessageIds.contains(message.id);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.86,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMessageBubble(message),
            ...List<Widget>.generate(
              message.transactions.length,
              (index) => _buildTransactionCard(
                message,
                index,
                message.transactions[index],
              ),
            ),
            if (message.hasTransactions)
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 4),
                child: message.isSaved
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x1A4ADE80),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x664ADE80)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF4ADE80),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Đã lưu giao dịch",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SizedBox(
                        width: 188,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () => _saveTransactionsForMessage(message),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1C84FF),
                                  Color(0xFF315EF6),
                                  Color(0xFF4C42D4),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _accentBlue.withValues(alpha: 0.24),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Xác nhận & Lưu",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(AIChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: message.sender == AIChatSender.user
          ? _buildMessageBubble(message)
          : _buildAiMessageContent(message),
    );
  }

  Widget _buildChatTimeline() {
    if (_isRestoringHistory) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_messages.isEmpty && !_isProcessing) {
      return _buildWelcomeState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      itemCount: _messages.length + (_isProcessing ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _messages.length) {
          return _buildTypingIndicator();
        }

        final message = _messages[index];
        return _buildChatItem(message);
      },
    );
  }

  Widget _buildSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Chọn nhanh",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            GestureDetector(
              onTap: _openQuickTemplateManager,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "Tạo card giao dịch sẵn để dùng khi AI hiểu chưa đúng ý bạn.",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.54),
            fontSize: 11,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        if (_quickTemplates.isEmpty)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _openQuickTemplateManager,
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Thêm mục Chọn nhanh đầu tiên",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickTemplates.length,
              separatorBuilder: (_, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final template = _quickTemplates[index];
                final accent = template.isCredit
                    ? const Color(0xFF7EE787)
                    : _suggestionAccents[index % _suggestionAccents.length];
                return Opacity(
                  opacity: _isProcessing ? 0.5 : 1,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _isProcessing
                          ? null
                          : () => _applyQuickTemplate(template),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: _glassGradient(
                            accent: accent,
                            baseAlpha: 0.18,
                            accentAlpha: 0.16,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Text(
                            template.label,
                            style: const TextStyle(
                              color: _surfaceInk,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildComposer() {
    final canSend = !_isProcessing && _inputController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSuggestionsSection(),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: TextField(
                          controller: _inputController,
                          minLines: 1,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white),
                          textInputAction: TextInputAction.send,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _submitInput(),
                          decoration: InputDecoration(
                            hintText: "Nhắn khoản thu/chi của bạn...",
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: canSend ? _submitInput : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: const Color(0xFF0F5BD8),
                          disabledBackgroundColor: Colors.white.withValues(
                            alpha: 0.12,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Icon(Icons.arrow_upward_rounded, size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C0638),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            color: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Nhập thu chi tự nhiên để AI tự động xử lý và lưu.",
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2348B8), Color(0xFF40168A), Color(0xFF21042F)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 90,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6D6CFF).withValues(alpha: 0.18),
                ),
              ),
            ),
            Positioned(
              top: 280,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF13B9FF).withValues(alpha: 0.14),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: _buildChatTimeline(),
                    ),
                  ),
                  _buildComposer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
