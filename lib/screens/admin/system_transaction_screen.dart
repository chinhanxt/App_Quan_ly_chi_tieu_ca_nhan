import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/responsive_layout.dart';

class SystemTransactionScreen extends StatefulWidget {
  const SystemTransactionScreen({super.key});

  @override
  State<SystemTransactionScreen> createState() => _SystemTransactionScreenState();
}

class _SystemTransactionScreenState extends State<SystemTransactionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Filter states
  String _selectedType = 'all'; // all, credit, debit
  String? _selectedUserId;
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _buildBody(context),
      desktopBody: AdminWebLayout(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 1100;

    return Scaffold(
      appBar: isDesktop ? null : AppBar(
        title: const Text("Bộ lọc nâng cao"),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            onPressed: () {
              setState(() {
                _selectedType = 'all';
                _selectedUserId = null;
                _selectedDateRange = null;
                _searchController.clear();
                _searchQuery = "";
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          _buildFilterPanel(),
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Tìm theo tiêu đề (ví dụ: tiền điện)...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text("Tất cả")),
                  DropdownMenuItem(value: 'credit', child: Text("Thu nhập")),
                  DropdownMenuItem(value: 'debit', child: Text("Chi tiêu")),
                ],
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    var users = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: _selectedUserId,
                      decoration: const InputDecoration(
                        labelText: "Lọc theo User",
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text("Tất cả User")),
                        ...users.map((u) => DropdownMenuItem(
                          value: u.id,
                          child: Text((u.data() as Map)['email'] ?? "Unknown", overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (v) => setState(() => _selectedUserId = v),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range),
                label: Text(_selectedDateRange == null 
                  ? "Ngày" 
                  : "${DateFormat('dd/MM').format(_selectedDateRange!.start)}-${DateFormat('dd/MM').format(_selectedDateRange!.end)}"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    DateTimeRange? res = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _selectedDateRange,
      locale: const Locale('vi', 'VN'),
      saveText: 'LƯU',
      helpText: 'CHỌN KHOẢNG NGÀY',
    );
    if (res != null) setState(() => _selectedDateRange = res);
  }

  Widget _buildTransactionList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var userDocs = userSnapshot.data!.docs;
        if (_selectedUserId != null) {
          userDocs = userDocs.where((u) => u.id == _selectedUserId).toList();
        }

        return ListView.builder(
          itemCount: userDocs.length,
          itemBuilder: (context, index) {
            String uid = userDocs[index].id;
            String userEmail = (userDocs[index].data() as Map<String, dynamic>)['email'] ?? "Unknown";

            return StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').doc(uid).collection('transactions').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, transSnapshot) {
                if (!transSnapshot.hasData) return const SizedBox.shrink();
                
                var filteredDocs = transSnapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  
                  // Filter by Type
                  if (_selectedType != 'all' && data['type'] != _selectedType) return false;
                  
                  // Filter by Search Query
                  if (_searchQuery.isNotEmpty && !(data['title'] ?? "").toString().toLowerCase().contains(_searchQuery)) return false;
                  
                  // Filter by Date Range
                  if (_selectedDateRange != null) {
                    DateTime date = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
                    if (date.isBefore(_selectedDateRange!.start) || date.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)))) return false;
                  }
                  
                  return true;
                }).toList();

                if (filteredDocs.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.grey[200],
                      width: double.infinity,
                      child: Text("User: $userEmail", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    ...filteredDocs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: data['type'] == 'credit' ? Colors.green[50] : Colors.red[50],
                          child: Icon(
                            data['type'] == 'credit' ? Icons.arrow_downward : Icons.arrow_upward,
                            color: data['type'] == 'credit' ? Colors.green : Colors.red,
                            size: 16,
                          ),
                        ),
                        title: Text(data['title'] ?? "No Title", style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                          "${DateFormat('dd/MM/yy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(data['timestamp']))} | ${data['category']}",
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Text(
                          "${data['type'] == 'credit' ? '+' : '-'}${data['amount']}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: data['type'] == 'credit' ? Colors.green : Colors.red,
                          ),
                        ),
                        onLongPress: () => _confirmDelete(uid, doc.id),
                      );
                    }),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String uid, String transId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Admin có chắc chắn muốn xóa giao dịch này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(
            onPressed: () async {
              await _firestore.collection('users').doc(uid).collection('transactions').doc(transId).delete();
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
