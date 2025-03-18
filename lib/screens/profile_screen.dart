import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFFA6B9FF), // Màu chủ đề
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 70, // Tăng kích thước avatar
                    backgroundImage: AssetImage('assets/images/avatar.jpg'), // Thay ảnh avatar
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Thuong",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    "thuong@example.com",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5, // Chiếm 50% màn hình còn lại
            child: Column(
              children: [
                _buildProfileOption(Icons.person, "Edit Profile"),
                _buildProfileOption(Icons.lock, "Change Password"),
                _buildProfileOption(Icons.settings, "Settings"),
                _buildProfileOption(Icons.logout, "Log Out"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF4A90E2)),
      title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)), // Tăng size chữ
      trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey), // Icon to hơn một chút
      onTap: () {},
    );
  }
}
