import 'package:flutter/material.dart';
import 'package:music_player_app/config/validator.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/user_provider.dart';
import '../../service/admin/admin_user_service.dart';
import '../../models/user.dart';

class AdminUserPage extends StatefulWidget {
  const AdminUserPage({super.key});

  @override
  AdminUserPageState createState() => AdminUserPageState();
}

class AdminUserPageState extends State<AdminUserPage> {
  final AdminUserService _userService = AdminUserService();
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  int limit = 10;
  int totalCount = 0;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    fetchUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredUsers = users;
      });
      fetchUsers();
    } else {
      fetchUsers(searchQuery: query);
    }
  }

  Future<void> fetchUsers({String? searchQuery}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = userProvider.user?.token;
      if (token == null) {
        throw Exception('Không có token xác thực');
      }

      final fetchedUsers = await _userService.getAllUsers(
        page: currentPage,
        limit: limit,
        searchQuery: searchQuery,
        token: token,
      );
      setState(() {
        users = fetchedUsers;
        filteredUsers = fetchedUsers;
        totalCount = fetchedUsers.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> createUser(Map<String, dynamic> userData, File? avatarFile) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _userService.createUser(
        firstName: userData['firstName'],
        lastName: userData['lastName'],
        email: userData['email'],
        mobile: userData['mobile'],
        password: userData['password'],
        role: userData['role'],
        address: userData['address'],
        avatarFile: avatarFile,
        token: userProvider.user?.token ?? '',
      );
      return;
    } catch (e) {
      throw e; // Ném lỗi để dialog xử lý
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _userService.deleteUser(
        userId: userId,
        token: userProvider.user?.token ?? '',
      );
      setState(() {
        users.removeWhere((entry) => (entry['user'] as User).id == userId);
        filteredUsers.removeWhere((entry) => (entry['user'] as User).id == userId);
        totalCount = users.length;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Đã xóa người dùng thành công'),
              ],
            ),
            backgroundColor: const Color(0xFF00B894),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Lỗi: $e'),
              ],
            ),
            backgroundColor: const Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> deleteSelectedUsers() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Vui lòng chọn ít nhất một người dùng'),
            ],
          ),
          backgroundColor: const Color(0xFFFDCB6E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa ${_selectedUserIds.length} người dùng đã chọn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await _userService.deleteMultipleUsers(
                  userIds: _selectedUserIds.toList(),
                  token: userProvider.user?.token ?? '',
                );
                setState(() {
                  users.removeWhere((entry) => _selectedUserIds.contains((entry['user'] as User).id));
                  filteredUsers.removeWhere((entry) => _selectedUserIds.contains((entry['user'] as User).id));
                  totalCount = users.length;
                  _selectedUserIds.clear();
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Đã xóa ${_selectedUserIds.length} người dùng thành công'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF00B894),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Lỗi: $e'),
                        ],
                      ),
                      backgroundColor: const Color(0xFFE74C3C),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Color(0xFFE74C3C))),
          ),
        ],
      ),
    );
  }

  void showCreateUserDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final mobileController = TextEditingController();
    final passwordController = TextEditingController();
    final addressController = TextEditingController();
    String role = 'user';
    File? avatarFile;
    String? firstNameError;
    String? lastNameError;
    String? emailError;
    String? mobileError;
    String? passwordError;
    String? apiError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          elevation: 8,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tạo người dùng mới',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: firstNameController,
                      label: 'Họ',
                      icon: Icons.person_outline,
                      isRequired: true,
                      errorText: firstNameError,
                      onChanged: (value) {
                        setState(() {
                          firstNameError = Validator.validateRequiredField(value, 'Họ');
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: lastNameController,
                      label: 'Tên',
                      icon: Icons.person_outline,
                      isRequired: true,
                      errorText: lastNameError,
                      onChanged: (value) {
                        setState(() {
                          lastNameError = Validator.validateRequiredField(value, 'Tên');
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      isRequired: true,
                      errorText: emailError,
                      onChanged: (value) {
                        setState(() {
                          emailError = Validator.validateEmail(value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: mobileController,
                      label: 'Số điện thoại',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      isRequired: true,
                      errorText: mobileError,
                      onChanged: (value) {
                        setState(() {
                          mobileError = Validator.validateMobile(value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: passwordController,
                      label: 'Mật khẩu',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      isRequired: true,
                      errorText: passwordError,
                      onChanged: (value) {
                        setState(() {
                          passwordError = Validator.validateRequiredField(value, 'Mật khẩu');
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: addressController,
                      label: 'Địa chỉ',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFDFE6E9)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: role,
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0984E3)),
                        items: [
                          DropdownMenuItem(
                            value: 'user',
                            child: Row(
                              children: [
                                const Icon(Icons.person, color: Color(0xFF0984E3)),
                                const SizedBox(width: 8),
                                const Text('Người dùng'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Row(
                              children: [
                                const Icon(Icons.admin_panel_settings, color: Color(0xFF0984E3)),
                                const SizedBox(width: 8),
                                const Text('Quản trị viên'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            role = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(type: FileType.image);
                        if (result != null) {
                          setState(() {
                            avatarFile = File(result.files.single.path!);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ảnh đại diện đã được chọn')),
                          );
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Chọn ảnh đại diện'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0984E3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (apiError != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        apiError!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF636E72),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              // Validation
                              setState(() {
                                firstNameError = Validator.validateRequiredField(firstNameController.text, 'Họ');
                                lastNameError = Validator.validateRequiredField(lastNameController.text, 'Tên');
                                emailError = Validator.validateEmail(emailController.text);
                                mobileError = Validator.validateMobile(mobileController.text);
                                passwordError = Validator.validateRequiredField(passwordController.text, 'Mật khẩu');
                                apiError = null; // Reset API error
                              });

                              if (firstNameError != null ||
                                  lastNameError != null ||
                                  emailError != null ||
                                  mobileError != null ||
                                  passwordError != null) {
                                return;
                              }

                              final userData = {
                                'firstName': firstNameController.text,
                                'lastName': lastNameController.text,
                                'email': emailController.text,
                                'mobile': mobileController.text,
                                'password': passwordController.text,
                                'role': role,
                                'address': addressController.text,
                              };

                              try {
                                await createUser(userData, avatarFile);
                                Navigator.pop(context);
                                fetchUsers(); // Refresh danh sách người dùng
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 8),
                                        const Text('Tạo người dùng thành công'),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF00B894),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    margin: const EdgeInsets.all(16),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              } catch (e) {
                                setState(() {
                                  apiError = e.toString();
                                  if (apiError!.contains('User has existed')) {
                                    apiError = 'Email đã tồn tại. Vui lòng sử dụng email khác.';
                                  } else if (apiError!.contains('Phone number has existed')) {
                                    apiError = 'Số điện thoại đã tồn tại. Vui lòng sử dụng số khác.';
                                  }
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0984E3),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Tạo'),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            labelText: label + (isRequired ? ' *' : ''),
            labelStyle: const TextStyle(color: Color(0xFF636E72), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF0984E3)),
            filled: true,
            fillColor: const Color(0xFFF5F6FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0984E3), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE74C3C)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 2),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(color: Color(0xFFE74C3C)),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Quản lý người dùng',
          style: TextStyle(
            color: Color(0xFF2D3436),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3436)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedUserIds.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: deleteSelectedUsers,
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                label: Text(
                  'Xóa (${_selectedUserIds.length})',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE74C3C),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: showCreateUserDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Thêm mới',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0984E3),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(screenWidth * 0.04, 24, screenWidth * 0.04, 0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên hoặc email',
                    hintStyle: const TextStyle(color: Color(0xFF636E72)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF0984E3)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0984E3)),
                        ),
                      )
                    : errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'Lỗi: $errorMessage',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          )
                        : filteredUsers.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Không tìm thấy người dùng nào',
                                    style: TextStyle(fontSize: 18, color: Color(0xFF636E72)),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                itemCount: filteredUsers.length,
                                separatorBuilder: (context, idx) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final entry = filteredUsers[index];
                                  final user = entry['user'] as User;
                                  return Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: const Color(0xFFDFE6E9),
                                        width: 1,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/admin/user/:uid',
                                        arguments: user.id,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: _selectedUserIds.contains(user.id),
                                              onChanged: (value) {
                                                setState(() {
                                                  if (value == true) {
                                                    _selectedUserIds.add(user.id);
                                                  } else {
                                                    _selectedUserIds.remove(user.id);
                                                  }
                                                });
                                              },
                                              activeColor: const Color(0xFF0984E3),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0984E3).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: user.avatarImgURL != null
                                                  ? ClipRRect(
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: Image.network(
                                                        user.avatarImgURL!,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) =>
                                                            const Icon(Icons.person, color: Color(0xFF0984E3)),
                                                      ),
                                                    )
                                                  : const Icon(Icons.person, color: Color(0xFF0984E3)),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    entry['fullName'],
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Color(0xFF2D3436),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    user.email,
                                                    style: const TextStyle(
                                                      color: Color(0xFF636E72),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF0984E3).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              user.role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                                                              size: 14,
                                                              color: const Color(0xFF0984E3),
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              user.role == 'admin' ? 'Quản trị viên' : 'Người dùng',
                                                              style: const TextStyle(
                                                                color: Color(0xFF0984E3),
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF636E72).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.calendar_today,
                                                              size: 14,
                                                              color: const Color(0xFF636E72),
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              '${user.createdAt?.day ?? 'N/A'}/${user.createdAt?.month ?? 'N/A'}/${user.createdAt?.year ?? 'N/A'}',
                                                              style: const TextStyle(
                                                                color: Color(0xFF636E72),
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: user.isBlocked
                                                    ? const Color(0xFFE74C3C).withOpacity(0.1)
                                                    : const Color(0xFF00B894).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    user.isBlocked ? Icons.block : Icons.check_circle,
                                                    size: 16,
                                                    color: user.isBlocked ? const Color(0xFFE74C3C) : const Color(0xFF00B894),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    user.isBlocked ? 'Đã khóa' : 'Hoạt động',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: user.isBlocked ? const Color(0xFFE74C3C) : const Color(0xFF00B894),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: currentPage > 1
                          ? () {
                              setState(() {
                                currentPage--;
                              });
                              fetchUsers();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      color: currentPage > 1 ? const Color(0xFF0984E3) : Colors.grey,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Trang $currentPage / ${(totalCount / limit).ceil()}',
                        style: const TextStyle(
                          color: Color(0xFF2D3436),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: currentPage < (totalCount / limit).ceil()
                          ? () {
                              setState(() {
                                currentPage++;
                              });
                              fetchUsers();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      color: currentPage < (totalCount / limit).ceil() ? const Color(0xFF0984E3) : Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}