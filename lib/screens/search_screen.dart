import 'package:app/utils/app_colors.dart';
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
      print("Lỗi tải giao dịch: $e");
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
            txDate.isAfter(_endDate!.add(const Duration(days: 1))))
          return false; // bao gồm cả ngày kết thúc
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Từ (Tối thiểu)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: maxController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Đến (Tối đa)'),
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tìm theo tên, ghi chú...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
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
      ),
      body: Column(
        children: [
          // Filter Chips Scrollable Bar
          Container(
            color: AppColors.accentSoft,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Lọc Loại
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text('Loại: $_selectedType'),
                      avatar: const Icon(Icons.swap_horiz, size: 16),
                      onPressed: () {
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
                      backgroundColor: _selectedType != 'Tất cả'
                          ? AppColors.accentSoft
                          : Colors.white,
                    ),
                  ),

                  // Lọc Danh mục
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text('Danh mục: $_selectedCategory'),
                      avatar: const Icon(Icons.category, size: 16),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
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
                                    setState(() => _selectedCategory = cat);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                      backgroundColor: _selectedCategory != 'Tất cả'
                          ? AppColors.accentSoft
                          : Colors.white,
                    ),
                  ),

                  // Lọc Thời gian
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        _startDate != null
                            ? DateFormat('dd/MM/yyyy').format(_startDate!)
                            : 'Thời gian',
                      ),
                      avatar: const Icon(Icons.date_range, size: 16),
                      onPressed: _showDatePicker,
                      backgroundColor: _startDate != null
                          ? AppColors.accentSoft
                          : Colors.white,
                    ),
                  ),

                  // Lọc Số tiền
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        _minAmount != null || _maxAmount != null
                            ? 'Đã lọc số tiền'
                            : 'Số tiền',
                      ),
                      avatar: const Icon(Icons.attach_money, size: 16),
                      onPressed: _showAmountFilterDialog,
                      backgroundColor: _minAmount != null || _maxAmount != null
                          ? AppColors.accentSoft
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Hiển thị nút Xóa bộ lọc nếu có lọc
          if (_selectedType != 'Tất cả' ||
              _selectedCategory != 'Tất cả' ||
              _startDate != null ||
              _minAmount != null ||
              _maxAmount != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Text(
                    'Đang lọc kết quả',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
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

          // Kết quả tìm kiếm
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty &&
                                  _selectedType == 'Tất cả' &&
                                  _selectedCategory == 'Tất cả' &&
                                  _startDate == null &&
                                  _minAmount == null
                              ? 'Nhập từ khóa hoặc chọn bộ lọc để tìm kiếm'
                              : 'Không tìm thấy giao dịch nào phù hợp!',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
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
