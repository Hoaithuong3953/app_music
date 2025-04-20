import 'package:flutter/material.dart';
import '../main.dart';
import '../service/user_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;
  final UserService _userService = UserService(baseUrl: 'http://10.0.2.2:8080');

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final user = await _userService.login(email: email, password: password);
      print("Phản hồi từ login: $user"); // Debug phản hồi từ server
      print("Token đã lưu: ${user['accessToken']}"); // Debug token

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      print("Lỗi đăng nhập: $e"); // Debug lỗi
      setState(() {
        if (e.toString().contains("This email does not exist")) {
          _errorText = "Email not found";
        } else if (e.toString().contains("Invalid Password")) {
          _errorText = "Invalid password";
        } else if (e.toString().contains("Missing Inputs")) {
          _errorText = "Please enter email and password";
        } else {
          _errorText = "Login failed";
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey[100]!,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo/app_logo_2.png',
                    height: 200,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Login to continue",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Email TextField
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.email, color: Color(0xFFA6B9FF)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFA6B9FF), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Password TextField
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFFA6B9FF)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFA6B9FF), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Hiển thị thông báo lỗi
                  if (_errorText != null)
                    Text(
                      _errorText!,
                      style: const TextStyle(color: Colors.red),
                      semanticsLabel: "error_message",
                    ),
                  const SizedBox(height: 16),
                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Điều hướng đến màn hình quên mật khẩu
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Color(0xFFA6B9FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Nút Login
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      key: const Key("login_button"),
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA6B9FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                        shadowColor: const Color(0xFFA6B9FF).withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        semanticsLabel: "login_button",
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Chuyển sang Register
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.grey),
                        children: [
                          TextSpan(
                            text: "Sign up",
                            style: TextStyle(
                              color: Color(0xFFA6B9FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}