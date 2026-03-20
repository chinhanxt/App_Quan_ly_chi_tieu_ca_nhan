import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppIcons {
  // 5 danh mục mặc định
  final List<Map<String, dynamic>> defaultCategories = [
    {"name": "Lương", "icon": FontAwesomeIcons.moneyBillWave, "iconName": "moneyBillWave"},
    {"name": "Mua sắm", "icon": FontAwesomeIcons.cartShopping, "iconName": "cartShopping"},
    {"name": "Ăn uống", "icon": FontAwesomeIcons.utensils, "iconName": "utensils"},
    {"name": "Di chuyển", "icon": FontAwesomeIcons.car, "iconName": "car"},
    {"name": "Tiết kiệm", "icon": FontAwesomeIcons.piggyBank, "iconName": "piggyBank"},
  ];

  // 26 icon gợi ý để người dùng thêm danh mục mới
  final List<Map<String, dynamic>> suggestedCategories = [
    {"name": "Ngân hàng", "icon": FontAwesomeIcons.buildingColumns, "iconName": "buildingColumns"},
    {"name": "Thẻ tín dụng", "icon": FontAwesomeIcons.creditCard, "iconName": "creditCard"},
    {"name": "Ví", "icon": FontAwesomeIcons.wallet, "iconName": "wallet"},
    {"name": "Thực phẩm", "icon": FontAwesomeIcons.basketShopping, "iconName": "basketShopping"},
    {"name": "Cà phê", "icon": FontAwesomeIcons.mugHot, "iconName": "mugHot"},
    {"name": "Xăng", "icon": FontAwesomeIcons.gasPump, "iconName": "gasPump"},
    {"name": "Taxi", "icon": FontAwesomeIcons.taxi, "iconName": "taxi"},
    {"name": "Du lịch", "icon": FontAwesomeIcons.plane, "iconName": "plane"},
    {"name": "Nhà", "icon": FontAwesomeIcons.house, "iconName": "house"},
    {"name": "Thuê", "icon": FontAwesomeIcons.key, "iconName": "key"},
    {"name": "Điện", "icon": FontAwesomeIcons.bolt, "iconName": "bolt"},
    {"name": "Nước", "icon": FontAwesomeIcons.faucet, "iconName": "faucet"},
    {"name": "Internet", "icon": FontAwesomeIcons.wifi, "iconName": "wifi"},
    {"name": "Điện thoại", "icon": FontAwesomeIcons.mobileScreen, "iconName": "mobileScreen"},
    {"name": "Sức khỏe", "icon": FontAwesomeIcons.heartPulse, "iconName": "heartPulse"},
    {"name": "Thuốc", "icon": FontAwesomeIcons.capsules, "iconName": "capsules"},
    {"name": "Giáo dục", "icon": FontAwesomeIcons.graduationCap, "iconName": "graduationCap"},
    {"name": "Sách", "icon": FontAwesomeIcons.book, "iconName": "book"},
    {"name": "Giải trí", "icon": FontAwesomeIcons.gamepad, "iconName": "gamepad"},
    {"name": "Âm nhạc", "icon": FontAwesomeIcons.music, "iconName": "music"},
    {"name": "Quà", "icon": FontAwesomeIcons.gift, "iconName": "gift"},
    {"name": "Đầu tư", "icon": FontAwesomeIcons.chartLine, "iconName": "chartLine"},
    {"name": "Thống kê", "icon": FontAwesomeIcons.chartPie, "iconName": "chartPie"},
    {"name": "Ngân sách", "icon": FontAwesomeIcons.calculator, "iconName": "calculator"},
    {"name": "An ninh", "icon": FontAwesomeIcons.lock, "iconName": "lock"},
    {"name": "Khác", "icon": FontAwesomeIcons.ellipsis, "iconName": "ellipsis"},
  ];

  IconData getIconData(String iconName) {
    // Tìm trong suggestedCategories
    var category = suggestedCategories.firstWhere(
      (c) => c['iconName'] == iconName,
      orElse: () => defaultCategories.firstWhere(
        (c) => c['iconName'] == iconName,
        orElse: () => {"icon": FontAwesomeIcons.cartShopping},
      ),
    );
    return category['icon'];
  }

  IconData getExpenseCategoryIcons(String categoryName) {
    // Kiểm tra trong danh mục mặc định
    var defaultCat = defaultCategories.firstWhere(
      (category) => category['name'] == categoryName,
      orElse: () => {},
    );
    if (defaultCat.isNotEmpty) return defaultCat['icon'];

    // Kiểm tra trong danh mục gợi ý
    var suggestedCat = suggestedCategories.firstWhere(
      (category) => category['name'] == categoryName,
      orElse: () => {},
    );
    if (suggestedCat.isNotEmpty) return suggestedCat['icon'];

    // Mặc định trả về cartShopping
    return FontAwesomeIcons.cartShopping;
  }
}
