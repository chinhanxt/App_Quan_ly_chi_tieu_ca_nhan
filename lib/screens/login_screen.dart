
import 'package:app/screens/sign_up.dart';
import 'package:app/screens/forgot_password_otp_screen.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/utils/appvalidator.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
    final _passWordController = TextEditingController();


  var authService = AuthService();
  var isLoader = false;
    Future<void> _submitForm() async {
      if (_formKey.currentState!.validate()){
          setState(() {
          isLoader = true;
        });


        
        var data = {
          "email": _emailController.text,
          "password": _passWordController.text,
        };


    await authService.login(data, context); 
if (!mounted) return;
   
    setState(() {
          isLoader = false;
        });

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
            child: Column(
          children: [
             SizedBox(
              height: 80.0,
            ),
            SizedBox(
              width: 300,
              child: Text("Đăng Nhập Tài Khoản", 
              textAlign: TextAlign.center,
              style: TextStyle
              (color: Colors.white,
              fontSize: 28, 
              fontWeight: FontWeight.bold),)),
          
            SizedBox(
              height: 20.0,
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
              controller: _passWordController,
              obscureText: true, // Ẩn mật khẩu
              style: TextStyle(color: Colors.white),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration:  _buildInputDecoration("Mật Khẩu", Icons.lock),
                 validator: appvalidator.validatePassWord
              
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ForgotPasswordOTPScreen(
                        initialEmail: _emailController.text,
                      ),
                    ),
                  );
                },
                child: const Text("Quên mật khẩu?", 
                  style: TextStyle(color: Color(0xFFFF5C04), fontSize: 16)),
              ),
            ),
             SizedBox(
              height: 20.0,
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

                Text("Đăng Nhập", style: TextStyle(fontSize: 20)))),
                
            ),
            SizedBox(
              height: 40.0,
            ),
            TextButton(onPressed: (){
              Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => SignUpView(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              ),
            );
            }, child: Text("Tạo Tài Khoản", style: TextStyle(color: Color(0xFFFF5C04),
            fontSize: 20),
            ),
            ),
            
            
          ],
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