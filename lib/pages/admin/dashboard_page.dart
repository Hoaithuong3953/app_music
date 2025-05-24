import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // Hàm đăng xuất
  Future<void> _logout(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.logout();

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildManagementCard(
              context,
              title: 'Quản lý Người dùng',
              icon: Icons.people,
              onTap: () => Navigator.pushNamed(context, '/admin/users'),
            ),
            _buildManagementCard(
              context,
              title: 'Quản lý Bài hát',
              icon: Icons.music_note,
              onTap: () => Navigator.pushNamed(context, '/admin/songs'),
            ),
            _buildManagementCard(
              context,
              title: 'Quản lý Thể loại',
              icon: Icons.category,
              onTap: () => Navigator.pushNamed(context, '/admin/genres'),
            ),
            _buildManagementCard(
              context,
              title: 'Quản lý Playlist',
              icon: Icons.playlist_play,
              onTap: () => Navigator.pushNamed(context, '/admin/playlists'),
            ),
            _buildManagementCard(
              context,
              title: 'Quản lý Nghệ sĩ',
              icon: Icons.person,
             onTap: () => Navigator.pushNamed(context, '/admin/artist'),
            ),
            _buildManagementCard(
              context,
              title: 'Quản lý Album',
              icon: Icons.album,
              onTap: () => Navigator.pushNamed(context, '/admin/albums'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}