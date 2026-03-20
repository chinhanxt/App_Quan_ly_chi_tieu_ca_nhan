import 'package:app/screens/login_screen.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/utils/appvalidator.dart';
import 'package:app/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignUpView extends StatefulWidget {
   SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _userNameController = TextEditingController();

  final _emailController = TextEditingController();

  final _phoneController = TextEditingController();

  final _passWordController = TextEditingController();

  var authService = AuthService();
  var isLoader = false;

    Future<void> _submitForm() async {
      if (_formKey.currentState!.validate()){
        setState(() {
          isLoader = true;
        });


        
        var data = {
          "name": _userNameController.text,
          "email": _emailController.text,
          "phone": _phoneController.text,
          "password": _passWordController.text,
          'remainingAmount': 0,
          'totalCredit': 0,
          'totalDebit': 0,
        };
    bool result = await authService.createUsser(data, context); 
    
    if (!mounted) return;
    setState(() {
          isLoader = false;
        });

    if (result) {
      CustomAlertDialog.show(
        context: context,
        title: "Đăng Ký Thành Công",
        message: "Chào mừng bạn! Hãy bắt đầu quản lý tài chính ngay nhé.",
        type: AlertType.success,
        onConfirm: () {
          Navigator.pop(context);
        },
      );
    }
      }
    }

  var appvalidator = Appvalidator();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     backgroundColor: Color(0xFF252634),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
            child: SingleChildScrollView( // Thêm scroll để tránh overflow trên màn hình nhỏ
              child: Column(
                children: [
                   SizedBox(
                    height: 80.0,
                  ),
                  SizedBox(
                    width: 250,
                    child: Text("Tạo Tài Khoản", 
                    textAlign: TextAlign.center,
                    style: TextStyle
                    (color: Colors.white,
                    fontSize: 28, 
                    fontWeight: FontWeight.bold),)),
                  SizedBox(
                    height: 50.0,
                  ),
                  TextFormField(
                    controller: _userNameController,
                    style: TextStyle(color: Colors.white),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: _buildInputDecoration("Tên Người Dùng", Icons.person),
                    validator: appvalidator.validateUsername
                  ),
                  SizedBox(
                    height: 16.0,
                  ),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: Colors.white),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration:  _buildInputDecoration("Email", Icons.email),
                       validator: appvalidator.validateEmail
                    
                  ),
                  SizedBox(
                    height: 16.0,
                  ),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(color: Colors.white),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration:  _buildInputDecoration("Số Điện Thoại", Icons.call),
                       validator: appvalidator.validatePhoneNumber
                    
                  ),
              
                  SizedBox(
                    height: 16.0,
                  ),
                   TextFormField(
                    controller: _passWordController,
                    
                    style: TextStyle(color: Colors.white),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration:  _buildInputDecoration("Mật Khẩu", Icons.lock),
                       validator: appvalidator.validatePassWord
                    
                  ),
                   SizedBox(
                    height: 40.0,
                  ),
                  SizedBox(
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(onPressed:(){
                        isLoader ? print("Loading") : _submitForm();
              
                      } , 
                      style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5C04),   // màu nền nút
                      foregroundColor: Colors.white,  // màu chữ
                      ),
                      child: isLoader ? Center(child: CircularProgressIndicator()):
              
                      Text("Tạo Tài Khoản", style: TextStyle(fontSize: 20)))),
                      
                  ),
                  SizedBox(
                    height: 40.0,
                  ),
                  TextButton(onPressed: (){
                    Navigator.pop(context); // Quay lại trang Login
                  },
                  child: Text("Đã có tài khoản? Đăng Nhập", style: TextStyle(color: Color(0xFFFF5C04),
                  fontSize: 20),
                  ),
                  ),
                  
                  
                ],
              ),
            )),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData suffixIcon){
    return InputDecoration(
      fillColor: Color(0xAA494A59),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0x35949494))
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0x35949494))),
      filled: true,
      labelStyle: TextStyle(color: Colors.white),
      labelText: label,
                suffixIcon: Icon(suffixIcon, 
                color: Color(0xFF949494),),
                border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0)));
  }
}