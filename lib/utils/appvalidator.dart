class Appvalidator {
      String? validateEmail(vaule){
      if(vaule!.isEmpty){
        return 'Vui Lòng Nhập Email';
      }
      RegExp emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegExp.hasMatch(vaule)){
        return 'Email Không Hợp Lệ';
      }
      return null;
    }
    String? validatePhoneNumber(value){
      if (value!.isEmpty){
        return 'Vui Lòng Nhập Số Điện Thoại';
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Số Điện Thoại Chỉ Được Chứa Số';
      }  
      if (value.length !=10){
        return 'Số Điện Thoại Phải Đủ 10 Số';
      }
      return null;
    }
    String? validateUsername(value){
      if(value!.isEmpty){
      return 'Vui Lòng Nhập Tên Người Dùng';
      }
      return null;
              
    }
    String? validatePassWord(value){
      if(value!.isEmpty){
        return 'Vui Lòng Nhập Mật Khẩu';
      }
      if(value.length < 8){
        return 'Mật Khẩu Phải Có Ít Nhất 8 Ký Tự';
      }
      return null;
    }

    String? isEmptyCheck(value){
      if(value!.isEmpty){
      return 'Vui Lòng Nhập Đầy Đủ';
      }
      return null;
              
    }

}