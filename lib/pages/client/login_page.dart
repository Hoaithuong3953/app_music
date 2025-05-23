import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_alert_dialog.dart';
import '../../config/validator.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false; // Thêm biến để quản lý trạng thái loading

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      _emailError = Validator.validateEmail(_emailController.text);
      _passwordError = Validator.validateRequiredField(_passwordController.text, 'Password');

      if (_emailError != null || _passwordError != null) {
        isValid = false;
      }
    });
    return isValid;
  }

  Future<void> _login() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.login(
        _emailController.text,
        _passwordController.text,
      );

      // Kiểm tra role và điều hướng phù hợp
      final user = userProvider.user;
      if (user != null) {
        showDialog(
          context: context,
          builder: (context) => CustomAlertDialog(
            isSuccess: true,
            title: 'Success',
            message: 'Login successful.',
            autoDismiss: true,
            autoDismissDuration: Duration(seconds: 2),
            onConfirm: () {
              if (user.role == 'admin') {
                Navigator.pushReplacementNamed(context, '/admin/dashboard');
              } else {
                Navigator.pushReplacementNamed(context, '/main');
              }
            },
          ),
        );
      }
    } catch (e) {
      String error = e.toString();
      if (error.contains("This email does not exist")) {
        error = "Email not found.";
      } else if (error.contains("Invalid Password")) {
        error = "Incorrect password.";
      } else if (error.contains("Missing Inputs")) {
        error = "Please enter both email and password.";
      } else {
        error = "Login failed. Please try again.";
      }
      showDialog(
        context: context,
        builder: (context) => CustomAlertDialog(
          isSuccess: false,
          title: 'Error',
          message: error,
          autoDismiss: true,
          autoDismissDuration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_note,
                      size: screenHeight * 0.15,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      'Login',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: screenHeight * 0.035,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    TextField(
                      controller: _emailController,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: screenHeight * 0.02,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: screenHeight * 0.018,
                          color: Colors.black54,
                        ),
                        prefixIcon: Icon(
                          Icons.email,
                          color: Theme.of(context).primaryColor,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    if (_emailError != null) ...[
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        _emailError!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: screenHeight * 0.016,
                        ),
                      ),
                    ],
                    SizedBox(height: screenHeight * 0.02),
                    TextField(
                      controller: _passwordController,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: screenHeight * 0.02,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: screenHeight * 0.018,
                          color: Colors.black54,
                        ),
                        prefixIcon: Icon(
                          Icons.lock,
                          color: Theme.of(context).primaryColor,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      obscureText: true,
                    ),
                    if (_passwordError != null) ...[
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        _passwordError!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: screenHeight * 0.016,
                        ),
                      ),
                    ],
                    SizedBox(height: screenHeight * 0.03),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                          horizontal: screenWidth * 0.15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: Size(screenWidth - 32, 56),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                              'Login',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: screenHeight * 0.02,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/register');
                      },
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Don't have an account? ",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: screenHeight * 0.02,
                                  ),
                            ),
                            TextSpan(
                              text: "Sign up",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: screenHeight * 0.02,
                                    color: Theme.of(context).highlightColor,
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
      ),
    );
  }
}