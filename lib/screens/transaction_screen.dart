import 'package:app/widgets/category_list.dart';
import 'package:app/widgets/tab_bar_view.dart';
import 'package:app/widgets/time_line_month.dart';
import 'package:app/screens/search_screen.dart'; // Import màn hình tìm kiếm
import 'package:flutter/material.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String monthYear = ""; 
  String category = "Tất cả"; // khởi tạo bằng tiếng Việt

  @override
  void initState(){
    super.initState();
    DateTime now = DateTime.now();
    setState(() {
      monthYear = "${now.month} ${now.year}"; // định dạng tháng tiếng Việt
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Giao Dịch", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TimeLineMonth(
            onChanges: (String? value) {
              if (value != null) {
                setState(() {
                  monthYear = value;
                });
              }
            },
          ),
          CategoryList(
            onChanges: (String? value) {
              if (value != null) {
                setState(() {
                  category = value;
                });
              }
            },
          ),
          Expanded(
            child: TypeTabBar(category: category, monthYear: monthYear),
          ),
        ],
      ),
    );
  }
}