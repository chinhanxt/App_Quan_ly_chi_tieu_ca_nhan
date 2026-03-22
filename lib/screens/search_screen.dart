import 'package:app/utils/app_colors.dart';
import 'package:app/widgets/app_chrome.dart';
import 'package:app/widgets/transaction_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  // Filters
  String _searchQuery = "";
  String _selectedType = "Tất cả"; // Tất cả, credit, debit
  String _selectedCategory = "Tất cả";
  DateTime? _startDate;
  DateTime? _endDate;
  int? _minAmount;
  int? _maxAmount;

  // Data cache for client-side filtering
  List<DocumentSnapshot> _allTransactions = [];
  bool _isLoading = true;
  List<String> _availableCategories = ["Tất cả"];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _loadCustomCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      List<String> categories = ["Tất cả"];

      // Default categories
      categories.addAll([
        "Lương",
        "Mua sắm",
        "Ăn uống",
        "Di chuyển",
        "Tiết kiệm",
      ]);

      if (doc.exists && doc.data()!.containsKey('customCategories')) {
        final customCats = List<Map<String, dynamic>>.from(
          doc['customCategories'],
        );
        for (var customCat in customCats) {
          if (!categories.contains(customCat['name'])) {
            categories.add(customCat['name']);
          }
        }
      }

      if (mounted) {
        setState(() {
          _availableCategories = categories;
        });
      }
    }
  }

  Future<void> _fetchTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Limit to last 1000 to avoid extreme memory/read costs, order by latest
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(1000)
          .get();

      if (mounted) {
        setState(() {
          _allTransactions = snapshot.docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải giao dịch: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<DocumentSnapshot> get _filteredTransactions {
    if (_allTransactions.isEmpty) return [];

    return _allTransactions.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // 1. Lọc Text (Tiêu đề)
      if (_searchQuery.isNotEmpty) {
        final title = (data['title'] ?? '').toString().toLowerCase();
        final cat = (data['category'] ?? '').toString().toLowerCase();
        final search = _searchQuery.toLowerCase();
        if (!title.contains(search) && !cat.contains(search)) {
          return false;
        }
      }

      // 2. Lọc Type
      if (_selectedType != 'Tất cả') {
        final type = _selectedType == 'Thu' ? 'credit' : 'debit';
        if (data['type'] != type) return false;
      }

      // 3. Lọc Danh mục
      if (_selectedCategory != 'Tất cả') {
        if (data['category'] != _selectedCategory) return false;
      }

      // 4. Lọc Ngày tháng
      if (_startDate != null || _endDate != null) {
        final timestamp = data['timestamp'] ?? 0;
        final txDate = DateTime.fromMillisecondsSinceEpoch(timestamp);

        if (_startDate != null && txDate.isBefore(_startDate!)) return false;
        if (_endDate != null &&
            txDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false; // bao gồm cả ngày kết thúc
        }
      }

      // 5. Lọc Số tiền
      final amount = data['amount'] is num
          ? (data['amount'] as num).toInt()
          : 0;
      if (_minAmount != null && amount < _minAmount!) return false;
      if (_maxAmount != null && amount > _maxAmount!) return false;

      return true;
    }).toList();
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'CHỌN NGÀY TÌM KIẾM',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
      fieldLabelText: 'Nhập ngày',
      errorFormatText: 'Sai định dạng ngày',
      errorInvalidText: 'Ngày không hợp lệ',
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _endDate = picked;
      });
    }
  }

  void _showAmountFilterDialog() {
    final TextEditingController minController = TextEditingController(
      text: _minAmount?.toString() ?? '',
    );
    final TextEditingController maxController = TextEditingController(
      text: _maxAmount?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Khoảng số tiền (VND)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                cursorColor: AppColors.primary,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Từ (Tối thiểu)',
                  fillColor: Color(0xFFFFF9F1),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: maxController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                cursorColor: AppColors.primary,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Đến (Tối đa)',
                  fillColor: Color(0xFFFFF9F1),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _minAmount = null;
                  _maxAmount = null;
                });
                Navigator.pop(context);
              },
              child: const Text('Xóa lọc', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _minAmount = int.tryParse(
                    minController.text.replaceAll(',', '').replaceAll('.', ''),
                  );
                  _maxAmount = int.tryParse(
                    maxController.text.replaceAll(',', '').replaceAll('.', ''),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Áp dụng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text('Tìm kiếm giao dịch'),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppHeroHeader(
              title: "Tìm giao dịch",
              subtitle:
                  "Lọc nhanh theo từ khóa, danh mục, thời gian và khoảng tiền trong cùng một chỗ.",
              trailing: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.manage_search_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppPanel(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên, ghi chú hoặc danh mục...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      fillColor: Color(0xFFFFF9F1),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = "";
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AppPill(
                            label: 'Loại: $_selectedType',
                            icon: Icons.swap_horiz_rounded,
                            isActive: _selectedType != 'Tất cả',
                            onTap: () {
                              setState(() {
                                if (_selectedType == 'Tất cả') {
                                  _selectedType = 'Thu Nhập';
                                } else if (_selectedType == 'Thu Nhập') {
                                  _selectedType = 'Chi Tiêu';
                                } else {
                                  _selectedType = 'Tất cả';
                                }
                              });
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AppPill(
                            label: 'Danh mục: $_selectedCategory',
                            icon: Icons.category_outlined,
                            isActive: _selectedCategory != 'Tất cả',
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                showDragHandle: true,
                                builder: (context) {
                                  return ListView.builder(
                                    itemCount: _availableCategories.length,
                                    itemBuilder: (context, index) {
                                      final cat = _availableCategories[index];
                                      return ListTile(
                                        title: Text(cat),
                                        trailing: _selectedCategory == cat
                                            ? const Icon(
                                                Icons.check,
                                                color: AppColors.accentStrong,
                                              )
                                            : null,
                                        onTap: () {
                                          setState(
                                            () => _selectedCategory = cat,
                                          );
                                          Navigator.pop(context);
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AppPill(
                            label: _startDate != null
                                ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                : 'Thời gian',
                            icon: Icons.date_range_rounded,
                            isActive: _startDate != null,
                            onTap: _showDatePicker,
                          ),
                        ),
                        AppPill(
                          label: _minAmount != null || _maxAmount != null
                              ? 'Khoảng tiền'
                              : 'Số tiền',
                          icon: Icons.payments_outlined,
                          isActive: _minAmount != null || _maxAmount != null,
                          onTap: _showAmountFilterDialog,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedType != 'Tất cả' ||
              _selectedCategory != 'Tất cả' ||
              _startDate != null ||
              _minAmount != null ||
              _maxAmount != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: AppPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      'Tìm thấy ${filtered.length} kết quả phù hợp',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedType = 'Tất cả';
                          _selectedCategory = 'Tất cả';
                          _startDate = null;
                          _endDate = null;
                          _minAmount = null;
                          _maxAmount = null;
                        });
                      },
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('Xóa lọc'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: "Không tìm thấy giao dịch",
                    message:
                        _searchQuery.isEmpty &&
                            _selectedType == 'Tất cả' &&
                            _selectedCategory == 'Tất cả' &&
                            _startDate == null &&
                            _minAmount == null
                        ? 'Nhập từ khóa hoặc chọn bộ lọc để bắt đầu tìm kiếm.'
                        : 'Không có giao dịch nào khớp với bộ lọc hiện tại.',
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      // Tái sử dụng TransactionCard
                      return TransactionCard(data: doc.data(), docId: doc.id);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
