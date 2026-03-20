import 'package:flutter/material.dart';

class TimeLineMonth extends StatefulWidget {
  const TimeLineMonth({super.key, required this.onChanges});
  final ValueChanged<String?> onChanges;

  @override
  State<TimeLineMonth> createState() => _TimeLineMonthState();
}

class _TimeLineMonthState extends State<TimeLineMonth> {
  String currentMonth = " ";
  List<String> months = [];

  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    for (int i = -18; i <= 0; i++) {
      DateTime iter = DateTime(now.year, now.month + i, 1);
      months.add("${iter.month} ${iter.year}");
    }
    currentMonth = "${now.month} ${now.year}";
    Future.delayed(Duration(seconds: 1), () {
      scrollToSelectedMonth();
    });
  }

  scrollToSelectedMonth() {
    final selectedMonthIndex = months.indexOf(currentMonth);
    if (selectedMonthIndex != -1 && scrollController.hasClients) {
      // Tính toán để item được chọn nằm ở giữa màn hình
      // Mỗi item có width 120 + margin 16 = 136
      final itemWidth = 136.0;
      final screenWidth = MediaQuery.sizeOf(context).width;
      final centerOffset = screenWidth / 2 - itemWidth / 2;
      final scrollOffset = selectedMonthIndex * itemWidth - centerOffset;

      // Đảm bảo không scroll quá đầu hoặc cuối
      final maxScroll = scrollController.position.maxScrollExtent;
      final clampedOffset = scrollOffset.clamp(0.0, maxScroll);

      scrollController.animateTo(
        clampedOffset,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      child: ListView.builder(
        controller: scrollController,
        itemCount: months.length,
        scrollDirection: Axis.horizontal,

        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                currentMonth = months[index];
                widget.onChanges(months[index]);
              });
              scrollToSelectedMonth();
            },
            child: Container(
              width: 120, // mở rộng ô lớn hơn nữa
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentMonth == months[index]
                    ? Colors.green
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  "Tháng ${months[index]}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: currentMonth == months[index]
                        ? Colors.white
                        : Colors.red,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
