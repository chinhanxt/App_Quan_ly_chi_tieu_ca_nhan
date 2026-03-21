class Appvalidator {
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập Email';
    }

    final RegExp emailRegExp = RegExp(
      r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
    );
    if (!emailRegExp.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Số điện thoại chỉ được chứa số';
    }
    if (value.length != 10) {
      return 'Số điện thoại phải đủ 10 số';
    }
    return null;
  }

  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập tên người dùng';
    }
    return null;
  }

  String? validatePassWord(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }
    return null;
  }

  String? isEmptyCheck(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập đầy đủ';
    }
    return null;
  }
}
