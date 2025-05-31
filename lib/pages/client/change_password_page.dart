import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_alert_dialog.dart';
import '../../config/validator.dart';

class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _oldPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      _oldPasswordError = Validator.validateRequiredField(_oldPasswordController.text, 'Old Password');
      _newPasswordError = Validator.validateRequiredField(_newPasswordController.text, 'New Password');
      _confirmPasswordError = Validator.validateRequiredField(_confirmPasswordController.text, 'Confirm Password');

      // Kiểm tra độ dài mật khẩu mới (ít nhất 8 ký tự)
      if (_newPasswordController.text.length < 8) {
        _newPasswordError = 'Password must be at least 8 characters long';
        isValid = false;
      }

      // Kiểm tra mật khẩu mới không trùng với mật khẩu cũ
      if (_newPasswordController.text == _oldPasswordController.text) {
        _newPasswordError = 'New password must be different from old password';
        isValid = false;
      }

      // Kiểm tra mật khẩu mới và xác nhận có khớp nhau không
      if (_newPasswordController.text != _confirmPasswordController.text) {
        _confirmPasswordError = 'Passwords do not match';
        isValid = false;
      }

      if (_oldPasswordError != null || _newPasswordError != null || _confirmPasswordError != null) {
        isValid = false;
      }
    });
    return isValid;
  }

  InputDecoration _buildInputDecoration(BuildContext context, String labelText, IconData icon, {bool isRequired = false}) {
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
      appBar: AppBar(
        title: Text(
          'Change Password',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: screenHeight * 0.025,
            color: Colors.black,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.03),
                TextField(
                  controller: _oldPasswordController,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: screenHeight * 0.02,
                    color: Colors.black,
                  ),
                  decoration: _buildInputDecoration(
                    context,
                    'Old Password',
                    Icons.lock,
                    isRequired: true,
                  ),
                  obscureText: true,
                ),
                if (_oldPasswordError != null) ...[
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    _oldPasswordError!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: screenHeight * 0.016,
                    ),
                  ),
                ],
                SizedBox(height: screenHeight * 0.02),
                TextField(
                  controller: _newPasswordController,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: screenHeight * 0.02,
                    color: Colors.black,
                  ),
                  decoration: _buildInputDecoration(
                    context,
                    'New Password',
                    Icons.lock,
                    isRequired: true,
                  ),
                  obscureText: true,
                ),
                if (_newPasswordError != null) ...[
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    _newPasswordError!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: screenHeight * 0.016,
                    ),
                  ),
                ],
                SizedBox(height: screenHeight * 0.02),
                TextField(
                  controller: _confirmPasswordController,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: screenHeight * 0.02,
                    color: Colors.black,
                  ),
                  decoration: _buildInputDecoration(
                    context,
                    'Confirm New Password',
                    Icons.lock,
                    isRequired: true,
                  ),
                  obscureText: true,
                ),
                if (_confirmPasswordError != null) ...[
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    _confirmPasswordError!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: screenHeight * 0.016,
                    ),
                  ),
                ],
                SizedBox(height: screenHeight * 0.03),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                    if (!_validateInputs()) return;

                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      await userProvider.changePassword(
                        oldPassword: _oldPasswordController.text, // Giữ tham số này để tương thích sau này
                        newPassword: _newPasswordController.text,
                      );
                      showDialog(
                        context: context,
                        builder: (context) => CustomAlertDialog(
                          isSuccess: true,
                          title: 'Success',
                          message: 'Password changed successfully.',
                          autoDismiss: true,
                          autoDismissDuration: Duration(seconds: 2),
                          onConfirm: () => Navigator.pop(context),
                        ),
                      );
                    } catch (e) {
                      String error = e.toString();
                      if (error.contains("Missing input")) {
                        error = "Please fill in all fields.";
                      } else {
                        error = "Failed to change password. Please try again.";
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
                    'Change Password',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: screenHeight * 0.02,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}