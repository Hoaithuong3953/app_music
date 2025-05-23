import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // Hàm đăng xuất
  Future<void> _logout(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.logout(); // Gọi logout từ UserProvider

    // Chuyển hướng về trang đăng nhập và xóa stack điều hướng
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login', // Route của trang đăng nhập
      (route) => false, // Xóa tất cả các route trước đó
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          // Nút đăng xuất
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text('Admin Dashboard - To be implemented'),
      ),
    );
  }
}