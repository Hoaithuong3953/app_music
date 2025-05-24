import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io'; // Thêm import để sử dụng File
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
    setState(() {
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users.where((entry) {
          final user = entry['user'] as User;
          final email = user.email.toLowerCase();
          final fullName = entry['fullName'].toLowerCase();
          return email.contains(query) || fullName.contains(query);
        }).toList();
      }
    });
  }

  Future<void> fetchUsers() async {
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
        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
        token: token,
      );
      setState(() {
        users = fetchedUsers;
        filteredUsers = fetchedUsers;
        totalCount = fetchedUsers.length; // Cần cập nhật nếu API trả về counts
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo người dùng thành công')),
      );
      fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _userService.deleteUser(
        userId: userId,
        token: userProvider.user?.token ?? '',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa người dùng thành công')),
      );
      fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> deleteSelectedUsers() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một người dùng')),
      );
      return;
    }
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _userService.deleteMultipleUsers(
        userIds: _selectedUserIds.toList(),
        token: userProvider.user?.token ?? '',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa nhiều người dùng thành công')),
      );
      setState(() {
        _selectedUserIds.clear();
      });
      fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tạo Người Dùng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'Họ'),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Tên'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: mobileController,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Địa chỉ'),
                ),
                DropdownButton<String>(
                  value: role,
                  isExpanded: true,
                  items: ['user', 'admin'].map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value == 'user' ? 'Người dùng' : 'Quản trị viên'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      role = value!;
                    });
                  },
                ),
                ElevatedButton(
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
                  child: const Text('Chọn Ảnh Đại Diện'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                if (firstNameController.text.isEmpty ||
                    lastNameController.text.isEmpty ||
                    emailController.text.isEmpty ||
                    mobileController.text.isEmpty ||
                    passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng điền đầy đủ các trường bắt buộc')),
                  );
                  return;
                }
                final userData = {
                  'firstName': firstNameController.text,
                  'lastName': lastNameController.text,
                  'email': emailController.text,
                  'mobile': mobileController.text,
                  'password': passwordController.text,
                  'role': role,
                  'address': addressController.text.isNotEmpty ? addressController.text : null,
                };
                createUser(userData, avatarFile);
                Navigator.pop(context);
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản lý Người Dùng',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm người dùng',
            onPressed: showCreateUserDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Xóa người dùng đã chọn',
            onPressed: deleteSelectedUsers,
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: EdgeInsets.fromLTRB(screenWidth * 0.04, 0, screenWidth * 0.04, 0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Tìm kiếm theo email hoặc tên',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                        ? Center(child: Text('Lỗi: $errorMessage'))
                        : filteredUsers.isEmpty
                            ? const Center(child: Text('Không tìm thấy người dùng'))
                            : ListView.builder(
                                itemCount: filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final entry = filteredUsers[index];
                                  final user = entry['user'] as User;
                                  final isSelected = _selectedUserIds.contains(user.id);
                                  return Row(
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedUserIds.add(user.id);
                                            } else {
                                              _selectedUserIds.remove(user.id);
                                            }
                                          });
                                        },
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => Navigator.pushNamed(
                                            context,
                                            '/admin/user/:uid',
                                            arguments: user.id,
                                          ),
                                          child: ListTile(
                                            leading: user.avatarImgURL != null
                                                ? CircleAvatar(
                                                    backgroundImage: NetworkImage(user.avatarImgURL!),
                                                  )
                                                : const Icon(Icons.person),
                                            title: Text(entry['fullName']),
                                            subtitle: Text(user.email),
                                            trailing: Text(user.role == 'admin' ? 'Quản trị viên' : 'Người dùng'),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Xác nhận Xóa'),
                                              content: Text('Bạn có chắc muốn xóa ${entry['fullName']}?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Hủy'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    deleteUser(user.id);
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('Xóa'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
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
                    ),
                    Text('Trang $currentPage / ${(totalCount / limit).ceil()}'),
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