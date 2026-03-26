import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../utils/responsive.dart';

class UserManagementWebScreen extends StatefulWidget {
  const UserManagementWebScreen({super.key});

  @override
  State<UserManagementWebScreen> createState() =>
      _UserManagementWebScreenState();
}

class _UserManagementWebScreenState extends State<UserManagementWebScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _sort<T>(
    Comparable<T>? Function(DocumentSnapshot) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Không có người dùng nào."));
        }

        List<DocumentSnapshot> users = snapshot.data!.docs.where((doc) {
          var email = (doc.data() as Map<String, dynamic>)['email'] ?? "";
          var name = (doc.data() as Map<String, dynamic>)['name'] ?? "";
          return email.toLowerCase().contains(_searchQuery) ||
              name.toLowerCase().contains(_searchQuery);
        }).toList();

        // Sắp xếp dữ liệu
        users.sort((a, b) {
          final field = _getColumnField(_sortColumnIndex);
          final dynamic aValue = (field == 'createdAt')
              ? (((a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?)
                        ?.toDate()
                        .millisecondsSinceEpoch ??
                    0)
              : ((a.data() as Map<String, dynamic>)[field]
                        ?.toString()
                        .toLowerCase() ??
                    "");
          final dynamic bValue = (field == 'createdAt')
              ? (((b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?)
                        ?.toDate()
                        .millisecondsSinceEpoch ??
                    0)
              : ((b.data() as Map<String, dynamic>)[field]
                        ?.toString()
                        .toLowerCase() ??
                    "");

          if (aValue is String && bValue is String) {
            return _sortAscending
                ? aValue.compareTo(bValue)
                : bValue.compareTo(aValue);
          } else if (aValue is int && bValue is int) {
            return _sortAscending
                ? aValue.compareTo(bValue)
                : bValue.compareTo(aValue);
          } else {
            return 0;
          }
        });

        final dataSource = UserDataSource(
          users,
          context,
          currencyFormat: NumberFormat.decimalPattern('vi_VN'),
        );

        return Padding(
          padding: EdgeInsets.all(Responsive.isDesktop(context) ? 20.0 : 16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Quản lý Người dùng",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Tìm kiếm theo Email hoặc Tên...",
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width > 1200
                          ? MediaQuery.of(context).size.width - 300
                          : 1000,
                      child: PaginatedDataTable(
                        key: ValueKey(
                          users.length,
                        ), // Add a key to force rebuild when users change
                        header: const Text('Danh sách người dùng'),
                        rowsPerPage: _rowsPerPage,
                        onRowsPerPageChanged: (value) {
                          setState(() {
                            _rowsPerPage = value!;
                          });
                        },
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _sortAscending,
                        columns: [
                          DataColumn(
                            label: const Text('Email'),
                            onSort: (columnIndex, ascending) => _sort(
                              (d) =>
                                  (d.data() as Map<String, dynamic>)['email'],
                              columnIndex,
                              ascending,
                            ),
                          ),
                          DataColumn(
                            label: const Text('Tên'),
                            onSort: (columnIndex, ascending) => _sort(
                              (d) => (d.data() as Map<String, dynamic>)['name'],
                              columnIndex,
                              ascending,
                            ),
                          ),
                          DataColumn(
                            label: const Text('Vai trò'),
                            onSort: (columnIndex, ascending) => _sort(
                              (d) => (d.data() as Map<String, dynamic>)['role'],
                              columnIndex,
                              ascending,
                            ),
                          ),
                          DataColumn(
                            label: const Text('Trạng thái'),
                            onSort: (columnIndex, ascending) => _sort(
                              (d) =>
                                  (d.data() as Map<String, dynamic>)['status'],
                              columnIndex,
                              ascending,
                            ),
                          ),
                          DataColumn(
                            label: const Text('Ngày tạo'),
                            onSort: (columnIndex, ascending) => _sort(
                              (d) =>
                                  (d.data()
                                      as Map<String, dynamic>)['createdAt'],
                              columnIndex,
                              ascending,
                            ),
                          ),
                          DataColumn(
                            label: const Text('Tổng Thu'),
                            numeric: true,
                            onSort: (columnIndex, ascending) => _sort(
                              (d) =>
                                  (d.data()
                                      as Map<String, dynamic>)['totalCredit'],
                              columnIndex,
                              ascending,
                            ),
                          ),
                          DataColumn(
                            label: const Text('Tổng Chi'),
                            numeric: true,
                            onSort: (columnIndex, ascending) => _sort(
                              (d) =>
                                  (d.data()
                                      as Map<String, dynamic>)['totalDebit'],
                              columnIndex,
                              ascending,
                            ),
                          ),
                          const DataColumn(label: Text('Thao tác')),
                        ],
                        source: dataSource,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getColumnField(int index) {
    switch (index) {
      case 0:
        return 'email';
      case 1:
        return 'name';
      case 2:
        return 'role';
      case 3:
        return 'status';
      case 4:
        return 'createdAt';
      case 5:
        return 'totalCredit';
      case 6:
        return 'totalDebit';
      default:
        return 'email';
    }
  }
}

class UserDataSource extends DataTableSource {
  final List<DocumentSnapshot> _users;
  final BuildContext _context;
  final NumberFormat currencyFormat;

  UserDataSource(this._users, this._context, {required this.currencyFormat});

  @override
  DataRow? getRow(int index) {
    if (index >= _users.length) return null;
    final user = _users[index];
    final data = user.data() as Map<String, dynamic>;

    String email = data['email'] ?? "N/A";
    String name = data['name'] ?? data['username'] ?? "Người dùng";
    String role = data['role'] ?? 'user';
    String status = data['status'] ?? 'active';
    DateTime createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
    int totalCredit = data['totalCredit'] ?? 0;
    int totalDebit = data['totalDebit'] ?? 0;

    return DataRow(
      cells: [
        DataCell(Text(email)),
        DataCell(Text(name)),
        DataCell(Text(role)),
        DataCell(Text(status)),
        DataCell(Text(DateFormat('dd/MM/yyyy').format(createdAt))),
        DataCell(Text(currencyFormat.format(totalCredit))),
        DataCell(Text(currencyFormat.format(totalDebit))),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                onPressed: () => _showEditUserDialog(user.id, data),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => _confirmDeleteUser(user.id, email),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _users.length;

  @override
  int get selectedRowCount => 0;

  void _showEditUserDialog(String userId, Map<String, dynamic> userData) {
    String currentRole = userData['role'] ?? 'user';
    String currentStatus = userData['status'] ?? 'active';

    showDialog(
      context: _context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Chỉnh sửa: ${userData['email']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: currentRole,
                decoration: const InputDecoration(labelText: "Vai trò"),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text("Người dùng")),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text("Quản trị viên"),
                  ),
                ],
                onChanged: (value) =>
                    setDialogState(() => currentRole = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: currentStatus,
                decoration: const InputDecoration(labelText: "Trạng thái"),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text("Hoạt động")),
                  DropdownMenuItem(value: 'locked', child: Text("Khóa")),
                ],
                onChanged: (value) =>
                    setDialogState(() => currentStatus = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({'role': currentRole, 'status': currentStatus});
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text("Lưu thay đổi"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUser(String userId, String email) {
    showDialog(
      context: _context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa người dùng"),
        content: Text(
          "Bạn có chắc chắn muốn xóa người dùng '${email}' này không? Hành động này không thể hoàn tác.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .delete();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
