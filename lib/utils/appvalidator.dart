class Appvalidator {
  String? validateEmail(String? value) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return 'Vui lòng nhập email để tiếp tục.';
    }

    final RegExp emailRegExp = RegExp(
      r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
    );
    if (!emailRegExp.hasMatch(trimmedValue)) {
      return 'Email chưa đúng định dạng. Ví dụ: ten@domain.com.';
    }
    return null;
  }

  String? validatePhoneNumber(String? value) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return 'Vui lòng nhập số điện thoại.';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmedValue)) {
      return 'Số điện thoại chỉ được nhập chữ số từ 0 đến 9.';
    }
    if (trimmedValue.length != 10) {
      return 'Số điện thoại phải gồm đúng 10 số.';
    }
    return null;
  }

  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tên người dùng.';
    }
    return null;
  }

  String? validatePassWord(String? value) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return 'Vui lòng nhập mật khẩu để tiếp tục.';
    }
    if (trimmedValue.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự.';
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
