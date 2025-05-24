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

      print('Lấy thông tin người dùng với ID: ${widget.userId}');
      final fetchedUserData = await _userService.getUserById(
        widget.userId,
        token: token,
      );
      print('Dữ liệu người dùng: $fetchedUserData');

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
      print('Danh sách bài hát: $songs');

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
        print('Bài hát yêu thích: $likedSongs');
      });
    } catch (e) {
      print('Lỗi tải danh sách bài hát yêu thích: $e');
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
          title: const Text('Chỉnh sửa Người Dùng'),
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(userData != null ? userData!['fullName'] : 'Chi tiết Người Dùng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: userData != null ? showEditUserDialog : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: userData != null
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xác nhận Xóa'),
                        content: Text('Bạn có chắc muốn xóa ${userData!['fullName']}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () {
                              deleteUser();
                              Navigator.pop(context);
                            },
                            child: const Text('Xóa'),
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
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Lỗi: $errorMessage'))
              : userData == null
                  ? const Center(child: Text('Không thể tải thông tin người dùng'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (userData!['user'].avatarImgURL != null)
                            Center(
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage: NetworkImage(userData!['user'].avatarImgURL!),
                                onBackgroundImageError: (exception, stackTrace) => const Icon(Icons.person),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text('Họ và Tên: ${userData!['fullName']}', style: const TextStyle(fontSize: 16)),
                          Text('Email: ${userData!['user'].email}', style: const TextStyle(fontSize: 16)),
                          Text('Số điện thoại: ${userData!['user'].mobile}', style: const TextStyle(fontSize: 16)),
                          Text('Vai trò: ${userData!['user'].role == 'admin' ? 'Quản trị viên' : 'Người dùng'}',
                              style: const TextStyle(fontSize: 16)),
                          Text('Trạng thái: ${userData!['user'].isBlocked ? 'Bị chặn' : 'Hoạt động'}',
                              style: const TextStyle(fontSize: 16)),
                          Text('Địa chỉ: ${userData!['user'].address ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                          Text(
                            'Tạo lúc: ${userData!['user'].createdAt != null ? userData!['user'].createdAt!.toLocal() : 'N/A'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          const Text('Bài hát yêu thích:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(),
                          likedSongs.isEmpty
                              ? const Center(child: Text('Không có bài hát yêu thích'))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: likedSongs.length,
                                  itemBuilder: (context, index) {
                                    final entry = likedSongs[index];
                                    final song = entry['song'] as Song;
                                    final artistName = entry['artistName'] as String;
                                    return ListTile(
                                      leading: song.coverImage != null
                                          ? Image.network(
                                              song.coverImage!,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note),
                                            )
                                          : const Icon(Icons.music_note),
                                      title: Text(song.title),
                                      subtitle: Text(artistName),
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/admin/song/:sid',
                                        arguments: song.id,
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
    );
  }
}