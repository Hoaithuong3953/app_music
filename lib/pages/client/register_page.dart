import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_alert_dialog.dart';
import '../../config/validator.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _mobileError;
  String? _passwordError;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      _firstNameError = Validator.validateRequiredField(_firstNameController.text, 'First Name');
      _lastNameError = Validator.validateRequiredField(_lastNameController.text, 'Last Name');
      _emailError = Validator.validateEmail(_emailController.text);
      _mobileError = Validator.validateMobile(_mobileController.text);
      _passwordError = Validator.validateRequiredField(_passwordController.text, 'Password');

      if (_firstNameError != null ||
          _lastNameError != null ||
          _emailError != null ||
          _mobileError != null ||
          _passwordError != null) {
        isValid = false;
      }
    });
    return isValid;
  }

  InputDecoration _buildInputDecoration(
      BuildContext context,
      String labelText,
      IconData icon, {
        bool isRequired = false,
      }) {
    final screenHeight = MediaQuery.of(context).size.height;
    return InputDecoration(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            labelText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: screenHeight * 0.018,
              color: Colors.black54,
            ),
          ),
          if (isRequired)
            Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontSize: screenHeight * 0.018,
              ),
            ),
        ],
      ),
      prefixIcon: Icon(
        icon,
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
    );
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
                      'Register',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: screenHeight * 0.035,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    TextField(
                      controller: _firstNameController,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: screenHeight * 0.02,
                        color: Colors.black,
                      ),
                      decoration: _buildInputDecoration(
                        context,
                        'First Name',
                        Icons.person,
                        isRequired: true,
                      ),
                    ),
                    if (_firstNameError != null) ...[
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        _firstNameError!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: screenHeight * 0.016,
                        ),
                      ),
                    ],
                    SizedBox(height: screenHeight * 0.02),
                    TextField(
                      controller: _lastNameController,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: screenHeight * 0.02,
                        color: Colors.black,
                      ),
                      decoration: _buildInputDecoration(
                        context,
                        'Last Name',
                        Icons.person,
                        isRequired: true,
                      ),
                    ),
                    if (_lastNameError != null) ...[
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        _lastNameError!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: screenHeight * 0.016,
                        ),
                      ),
                    ],
                    SizedBox(height: screenHeight * 0.02),
                    TextField(
                      controller: _emailController,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: screenHeight * 0.02,
                        color: Colors.black,
                      ),
                      decoration: _buildInputDecoration(
                        context,
                        'Email',
                        Icons.email,
                        isRequired: true,
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
                      controller: _mobileController,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: screenHeight * 0.02,
                        color: Colors.black,
                      ),
                      decoration: _buildInputDecoration(
                        context,
                        'Mobile',
                        Icons.phone,
                        isRequired: true,
                      ),
                    ),
                    if (_mobileError != null) ...[
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        _mobileError!,
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
                      decoration: _buildInputDecoration(
                        context,
                        'Password',
                        Icons.lock,
                        isRequired: true,
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
                      onPressed: _isLoading ? null : () async {
                        if (!_validateInputs()) return;

                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          final userProvider = Provider.of<UserProvider>(context, listen: false);
                          await userProvider.register(
                            firstName: _firstNameController.text.trim(),
                            lastName: _lastNameController.text.trim(),
                            email: _emailController.text.trim(),
                            mobile: _mobileController.text.trim(),
                            password: _passwordController.text.trim(),
                          );

                          showDialog(
                            context: context,
                            builder: (context) => CustomAlertDialog(
                              isSuccess: true,
                              title: 'Success',
                              message: 'Registration successful.',
                              autoDismiss: true,
                              autoDismissDuration: Duration(seconds: 2),
                              onConfirm: () {
                                Navigator.pushReplacementNamed(context, '/main');
                              },
                            ),
                          );
                        } catch (e) {
                          String error = e.toString();
                          if (error.contains("Email already exists")) {
                            error = "Email is already registered.";
                          } else if (error.contains("Mobile already exists")) {
                            error = "Mobile number is already registered.";
                          } else if (error.contains("Missing Inputs")) {
                            error = "Please fill in all required fields.";
                          } else {
                            error = "Registration failed. Please try again.";
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
                      },
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
                        'Register',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: screenHeight * 0.02,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: screenHeight * 0.02,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: Text(
                            "Login",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: screenHeight * 0.02,
                              color: Theme.of(context).highlightColor,
                            ),
                          ),
                        ),
                      ],
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