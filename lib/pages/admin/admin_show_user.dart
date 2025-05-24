import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/user_provider.dart';
import '../../service/admin/admin_user_service.dart';
import '../../service/client/song_service.dart';
import '../../models/user.dart';
import '../../models/song.dart';

class AdminShowUserPage extends StatefulWidget {
  final String userId;

  const AdminShowUserPage({super.key, required this.userId});

  @override
  AdminShowUserPageState createState() => AdminShowUserPageState();
}

class AdminShowUserPageState extends State<AdminShowUserPage> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> likedSongs = [];
  bool isLoading = true;
  String? errorMessage;
  final AdminUserService _userService = AdminUserService();
  final SongService _songService = SongService();

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
    fetchLikedSongs();
  }

  Future<void> fetchUserDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = userProvider.user?.token;
      if (token == null) {
        throw Exception('Không có token xác thực. Vui lòng đăng nhập lại.');
      }

      final fetchedUserData = await _userService.getUserById(
        widget.userId,
        token: token,
      );

      setState(() {
        userData = fetchedUserData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> fetchLikedSongs() async {
    try {
      final songs = await _songService.getAllSongs();
      setState(() {
        likedSongs = songs
            .where((entry) {
              final song = entry['song'] as Song?;
              if (song == null || song.likes == null) return false;
              return song.likes.contains(widget.userId);
            })
            .map((entry) => ({
                  'song': entry['song'] as Song,
                  'artistName': entry['artistName'] as String? ?? 'Không rõ nghệ sĩ',
                }))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách bài hát yêu thích: $e')),
      );
    }
  }

  Future<void> deleteUser() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _userService.deleteUser(
        userId: widget.userId,
        token: userProvider.user?.token ?? '',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa người dùng thành công')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> updateUser({
    String? firstName,
    String? lastName,
    String? email,
    String? mobile,
    String? password,
    String? role,
    bool? isBlocked,
    String? address,
    File? avatarFile,
  }) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _userService.updateUser(
        userId: widget.userId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        mobile: mobile,
        password: password,
        role: role,
        isBlocked: isBlocked,
        address: address,
        avatarFile: avatarFile,
        token: userProvider.user?.token ?? '',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật người dùng thành công')),
      );
      fetchUserDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void showEditUserDialog() {
    if (userData == null || userData!['user'] == null) return;

    final user = userData!['user'] as User;
    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);
    final emailController = TextEditingController(text: user.email);
    final mobileController = TextEditingController(text: user.mobile);
    final addressController = TextEditingController(text: user.address);
    final passwordController = TextEditingController();
    String role = user.role;
    bool isBlocked = user.isBlocked;
    File? avatarFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chỉnh sửa người dùng'),
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
                  decoration: const InputDecoration(labelText: 'Mật khẩu mới (nếu thay đổi)'),
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
                CheckboxListTile(
                  title: const Text('Chặn người dùng'),
                  value: isBlocked,
                  onChanged: (value) {
                    setState(() {
                      isBlocked = value!;
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
                updateUser(
                  firstName: firstNameController.text,
                  lastName: lastNameController.text,
                  email: emailController.text,
                  mobile: mobileController.text,
                  password: passwordController.text.isNotEmpty ? passwordController.text : null,
                  role: role,
                  isBlocked: isBlocked,
                  address: addressController.text.isNotEmpty ? addressController.text : null,
                  avatarFile: avatarFile,
                );
                Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          userData != null ? userData!['fullName'] : 'Chi tiết người dùng',
          style: const TextStyle(
            color: Color(0xFF2D3436),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0984E3)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF0984E3)),
            onPressed: userData != null ? showEditUserDialog : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
            onPressed: userData != null
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          'Xác nhận xóa',
                          style: TextStyle(
                            color: Color(0xFF2D3436),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Text(
                          'Bạn có chắc chắn muốn xóa người dùng ${userData!['fullName']}?',
                          style: const TextStyle(
                            color: Color(0xFF636E72),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Hủy',
                              style: TextStyle(color: Color(0xFF636E72)),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              deleteUser();
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Xóa',
                              style: TextStyle(color: Color(0xFFE74C3C)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
      body: isLoading
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
              : userData == null
                  ? const Center(
                      child: Text(
                        'Không thể tải thông tin người dùng',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF636E72),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar Section
                          Center(
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0984E3).withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 70,
                                backgroundColor: const Color(0xFF0984E3).withOpacity(0.1),
                                child: userData!['user'].avatarImgURL != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(70),
                                        child: Image.network(
                                          userData!['user'].avatarImgURL!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.person, size: 70, color: Color(0xFF0984E3)),
                                        ),
                                      )
                                    : const Icon(Icons.person, size: 70, color: Color(0xFF0984E3)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // User Info Section
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person_outline,
                                        color: Color(0xFF0984E3),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Thông tin cá nhân',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2D3436),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  _buildInfoRow('Email', userData!['user'].email),
                                  _buildInfoRow('Số điện thoại', userData!['user'].mobile),
                                  _buildInfoRow('Vai trò', userData!['user'].role == 'admin' ? 'Quản trị viên' : 'Người dùng'),
                                  _buildInfoRow('Địa chỉ', userData!['user'].address ?? 'Chưa cập nhật'),
                                  _buildInfoRow(
                                    'Trạng thái',
                                    userData!['user'].isBlocked ? 'Đã khóa' : 'Hoạt động',
                                    valueColor: userData!['user'].isBlocked ? const Color(0xFFE74C3C) : const Color(0xFF00B894),
                                  ),
                                  _buildInfoRow(
                                    'Ngày tạo',
                                    userData!['user'].createdAt.toLocal().toString().split('.')[0],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Liked Songs Section
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.favorite,
                                        color: Color(0xFFE74C3C),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Bài hát yêu thích',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2D3436),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  if (likedSongs.isEmpty)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.music_note,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Chưa có bài hát yêu thích',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: likedSongs.length,
                                      itemBuilder: (context, index) {
                                        final song = likedSongs[index];
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: BorderSide(
                                              color: Colors.grey.withOpacity(0.2),
                                            ),
                                          ),
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            leading: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: song['song'].coverImage != null
                                                  ? Image.network(
                                                      song['song'].coverImage!,
                                                      width: 50,
                                                      height: 50,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          Container(
                                                            width: 50,
                                                            height: 50,
                                                            color: Colors.grey[200],
                                                            child: const Icon(Icons.music_note),
                                                          ),
                                                    )
                                                  : Container(
                                                      width: 50,
                                                      height: 50,
                                                      color: Colors.grey[200],
                                                      child: const Icon(Icons.music_note),
                                                    ),
                                            ),
                                            title: Text(
                                              song['song'].title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF2D3436),
                                              ),
                                            ),
                                            subtitle: Text(
                                              song['artistName'],
                                              style: const TextStyle(
                                                color: Color(0xFF636E72),
                                              ),
                                            ),
                                            onTap: () => Navigator.pushNamed(
                                              context,
                                              '/admin/song/:sid',
                                              arguments: song['song'].id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF636E72),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF2D3436),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}