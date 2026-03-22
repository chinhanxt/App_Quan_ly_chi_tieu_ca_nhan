import 'package:flutter/material.dart';
import 'package:app/utils/app_colors.dart';

class TimeLineMonth extends StatefulWidget {
  const TimeLineMonth({super.key, required this.onChanges});
  final ValueChanged<String?> onChanges;

  @override
  State<TimeLineMonth> createState() => _TimeLineMonthState();
}

class _TimeLineMonthState extends State<TimeLineMonth> {
  static const Color _selectedMonthColor = Color(0xFF5EAA74);
  static const Color _unselectedMonthText = Color(0xFF6E756F);

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

  void scrollToSelectedMonth() {
    final selectedMonthIndex = months.indexOf(currentMonth);
    if (selectedMonthIndex != -1 && scrollController.hasClients) {
      final itemWidth = 144.0;
      final screenWidth = MediaQuery.sizeOf(context).width;
      final centerOffset = screenWidth / 2 - itemWidth / 2;
      final scrollOffset = selectedMonthIndex * itemWidth - centerOffset;
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
      height: 52,
      margin: const EdgeInsets.fromLTRB(8, 10, 8, 2),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.only(left: 4, right: 44),
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
              width: 128,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentMonth == months[index]
                    ? _selectedMonthColor
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: currentMonth == months[index]
                      ? _selectedMonthColor
                      : AppColors.primary.withValues(alpha: 0.08),
                ),
                boxShadow: currentMonth == months[index]
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  "Tháng ${months[index]}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: currentMonth == months[index]
                        ? Colors.white
                        : _unselectedMonthText,
                    fontWeight: currentMonth == months[index]
                        ? FontWeight.w700
                        : FontWeight.w600,
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
