import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_alert_dialog.dart';
import '../../config/validator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController? _firstNameController;
  TextEditingController? _lastNameController;
  TextEditingController? _emailController;
  TextEditingController? _mobileController;
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _mobileError;
  File? _selectedImage;
  bool _removeAvatar = false;
  bool _isLoading = false;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    print('EditProfilePage initState called');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('EditProfilePage didChangeDependencies called');
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    print('User in didChangeDependencies: $user');
    
    if (!_controllersInitialized && user != null) {
      _firstNameController = TextEditingController(text: user.firstName ?? '');
      _lastNameController = TextEditingController(text: user.lastName ?? '');
      _emailController = TextEditingController(text: user.email ?? '');
      _mobileController = TextEditingController(text: user.mobile ?? '');
      _controllersInitialized = true;
      print('Controllers initialized');
    }
  }

  @override
  void dispose() {
    print('EditProfilePage dispose called');
    _firstNameController?.dispose();
    _lastNameController?.dispose();
    _emailController?.dispose();
    _mobileController?.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      _firstNameError = Validator.validateRequiredField(_firstNameController?.text, 'First Name');
      _lastNameError = Validator.validateRequiredField(_lastNameController?.text, 'Last Name');
      _emailError = Validator.validateEmail(_emailController?.text);
      _mobileError = Validator.validateMobile(_mobileController?.text);

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
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chức năng chọn ảnh chỉ hỗ trợ trên mobile/desktop.')),
      );
      return;
    }
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _removeAvatar = false;
      });
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
        firstName: _firstNameController?.text.trim() ?? '',
        lastName: _lastNameController?.text.trim() ?? '',
        email: _emailController?.text.trim() ?? '',
        mobile: _mobileController?.text.trim() ?? '',
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => CustomAlertDialog(
            isSuccess: true,
            title: 'Success',
            message: 'Profile updated successfully.',
            autoDismiss: true,
            autoDismissDuration: const Duration(seconds: 2),
            onConfirm: () => Navigator.pop(context),
          ),
        );
      }
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
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => CustomAlertDialog(
            isSuccess: false,
            title: 'Error',
            message: error,
            autoDismiss: true,
            autoDismissDuration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('EditProfilePage build called');
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null || !_controllersInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                        child: _selectedImage != null && !kIsWeb
                            ? Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: screenHeight * 0.16,
                                height: screenHeight * 0.16,
                              )
                            : (user.avatarImgURL != null && !_removeAvatar
                                ? Image.network(
                                    user.avatarImgURL!,
                                    fit: BoxFit.cover,
                                    width: screenHeight * 0.16,
                                    height: screenHeight * 0.16,
                                    errorBuilder: (context, error, stackTrace) => Text(
                                      (_firstNameController?.text.isNotEmpty ?? false)
                                          ? _firstNameController!.text[0].toUpperCase()
                                          : 'U',
                                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                        fontSize: screenHeight * 0.06,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    (_firstNameController?.text.isNotEmpty ?? false)
                                        ? _firstNameController!.text[0].toUpperCase()
                                        : 'U',
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
                            ? const CircularProgressIndicator(
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
                  decoration: InputDecoration(
                    labelText: 'First Name *',
                    prefixIcon: Icon(
                      Icons.person,
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
                  decoration: InputDecoration(
                    labelText: 'Last Name *',
                    prefixIcon: Icon(
                      Icons.person,
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
                  decoration: InputDecoration(
                    labelText: 'Email *',
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
                  controller: _mobileController,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: screenHeight * 0.02,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Mobile *',
                    prefixIcon: Icon(
                      Icons.phone,
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