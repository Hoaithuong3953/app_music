import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_alert_dialog.dart';
import '../../config/validator.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _mobileError;
  File? _selectedImage;
  bool _removeAvatar = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _mobileController = TextEditingController(text: user?.mobile ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      _firstNameError = Validator.validateRequiredField(_firstNameController.text, 'First Name');
      _lastNameError = Validator.validateRequiredField(_lastNameController.text, 'Last Name');
      _emailError = Validator.validateEmail(_emailController.text);
      _mobileError = Validator.validateMobile(_mobileController.text);

      if (_firstNameError != null ||
          _lastNameError != null ||
          _emailError != null ||
          _mobileError != null) {
        isValid = false;
      }
    });
    return isValid;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final tempImage = File(pickedFile.path);
      bool tempRemoveAvatar = false;

      // Hiển thị popup điều chỉnh ảnh
      await showDialog(
        context: context,
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;
          final dialogWidth = screenWidth * 0.9;
          final dialogHeight = screenHeight * 0.6;
          final previewSize = dialogWidth * 0.5;
          double scale = 1.0;
          double dx = 0.0;
          double dy = 0.0;

          return Dialog(
            child: Container(
              width: dialogWidth,
              height: dialogHeight,
              padding: EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Adjust Avatar',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ảnh gốc mờ làm nền
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.3,
                                child: Transform(
                                  transform: Matrix4.identity()
                                    ..scale(scale)
                                    ..translate(dx, dy),
                                  child: Image.file(
                                    tempImage,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            // Vùng điều chỉnh hình tròn trong suốt
                            GestureDetector(
                              onScaleUpdate: (details) {
                                setDialogState(() {
                                  scale = details.scale.clamp(0.5, 4.0);
                                  dx += details.focalPointDelta.dx / scale;
                                  dy += details.focalPointDelta.dy / scale;
                                });
                              },
                              child: Container(
                                width: previewSize,
                                height: previewSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black54, width: 2),
                                ),
                                child: ClipOval(
                                  child: Transform(
                                    transform: Matrix4.identity()
                                      ..scale(scale)
                                      ..translate(dx, dy),
                                    child: Image.file(
                                      tempImage,
                                      fit: BoxFit.cover,
                                      width: previewSize,
                                      height: previewSize,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              tempRemoveAvatar = true;
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Remove',
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                if (!tempRemoveAvatar) {
                                  _selectedImage = tempImage;
                                  _removeAvatar = false;
                                } else {
                                  _selectedImage = null;
                                  _removeAvatar = true;
                                }
                              });
                            },
                            child: Text(
                              'Done',
                              style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (_removeAvatar) {
        await userProvider.removeAvatar();
      } else if (_selectedImage != null) {
        await userProvider.updateAvatar(_selectedImage!);
      }

      await userProvider.updateUser(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
      );

      showDialog(
        context: context,
        builder: (context) => CustomAlertDialog(
          isSuccess: true,
          title: 'Success',
          message: 'Profile updated successfully.',
          autoDismiss: true,
          autoDismissDuration: Duration(seconds: 2),
          onConfirm: () => Navigator.pop(context),
        ),
      );
    } catch (e) {
      String error = e.toString();
      if (error.contains("Email already exists")) {
        error = "Email is already registered.";
      } else if (error.contains("Mobile already exists")) {
        error = "Mobile number is already registered.";
      } else if (error.contains("Missing input")) {
        error = "Please fill in at least one field.";
      } else {
        error = "Failed to update profile. Please try again.";
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
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
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
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: screenHeight * 0.08,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: ClipOval(
                        child: _selectedImage != null
                            ? Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: screenHeight * 0.16,
                          height: screenHeight * 0.16,
                        )
                            : (user?.avatarImgURL != null && !_removeAvatar
                            ? Image.network(
                          user!.avatarImgURL!,
                          fit: BoxFit.cover,
                          width: screenHeight * 0.16,
                          height: screenHeight * 0.16,
                          errorBuilder: (context, error, stackTrace) => Text(
                            (_firstNameController.text.isNotEmpty
                                ? _firstNameController.text[0].toUpperCase()
                                : 'U'),
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontSize: screenHeight * 0.06,
                              color: Colors.white,
                            ),
                          ),
                        )
                            : Text(
                          (_firstNameController.text.isNotEmpty
                              ? _firstNameController.text[0].toUpperCase()
                              : 'U'),
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: screenHeight * 0.06,
                            color: Colors.white,
                          ),
                        )),
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: screenHeight * 0.02,
                        backgroundColor: Theme.of(context).highlightColor,
                        child: _isLoading
                            ? CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                            : Icon(
                          Icons.camera_alt,
                          size: screenHeight * 0.02,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
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
                SizedBox(height: screenHeight * 0.03),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
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
                    'Save Changes',
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