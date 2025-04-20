import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';
import '../service/user_service.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = "Loading...";
  String _email = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<User?> _loadUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userMap);
    }
    return null;
  }

  Future<void> _loadUserInfo() async {
    try {
      const String baseUrl = "http://10.0.2.2:8080";
      final userService = UserService(baseUrl: baseUrl);
      User? user = await userService.getCurrentUser();

      if (user == null) {
        debugPrint("User is null from API. Trying to load from SharedPreferences.");
        user = await _loadUserFromPreferences();
      }

      if (user == null) {
        // Không có dữ liệu user, chuyển hướng đến màn hình đăng nhập
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }

      // Gán vào biến không nullable để đảm bảo an toàn null
      final nonNullUser = user;

      setState(() {
        _username = nonNullUser.firstName.trim().isNotEmpty
            ? nonNullUser.firstName
            : (nonNullUser.email.trim().isNotEmpty
            ? nonNullUser.email
            : "Unknown User");
        _email = nonNullUser.email.trim().isNotEmpty ? nonNullUser.email : "Unknown Email";
      });
    } catch (e) {
      debugPrint("Lỗi khi tải thông tin người dùng: $e");
      setState(() {
        _username = "Unknown User";
        _email = "Unknown Email";
      });
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFA6B9FF).withOpacity(0.9),
                  const Color(0xFFA6B9FF).withOpacity(0.6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundImage: AssetImage('assets/images/logo/avatar.jpg'),
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _username,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _email,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: Column(
                children: [
                  _buildProfileOption(
                    icon: Icons.person,
                    title: "Edit Profile",
                    onTap: () {},
                  ),
                  _buildProfileOption(
                    icon: Icons.lock,
                    title: "Change Password",
                    onTap: () {},
                  ),
                  _buildProfileOption(
                    icon: Icons.settings,
                    title: "Settings",
                    onTap: () {},
                  ),
                  _buildProfileOption(
                    icon: Icons.logout,
                    title: "Log Out",
                    onTap: _logout,
                    textColor: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? const Color(0xFFA6B9FF), size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: textColor ?? Colors.grey),
          ],
        ),
      ),
    );
  }
}