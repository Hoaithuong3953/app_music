import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/user_provider.dart';
import '../../service/admin/admin_playlist_service.dart';
import '../../service/client/playlist_service.dart';
import '../../widgets/client/playlist_card.dart';
import '../../models/playlist.dart';

class AdminPlaylistPage extends StatefulWidget {
  const AdminPlaylistPage({super.key});

  @override
  _AdminPlaylistPageState createState() => _AdminPlaylistPageState();
}

class _AdminPlaylistPageState extends State<AdminPlaylistPage> {
  final AdminPlaylistService _adminPlaylistService = AdminPlaylistService();
  final PlaylistService _playlistService = PlaylistService();
  List<Map<String, dynamic>> playlists = [];
  List<Map<String, dynamic>> filteredPlaylists = [];
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  int limit = 10;
  int totalCount = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPlaylists();
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
        filteredPlaylists = playlists;
      } else {
        filteredPlaylists = playlists.where((entry) {
          final userName = entry['userName']?.toLowerCase() ?? '';
          final userEmail = entry['userEmail']?.toLowerCase() ?? '';
          return userName.contains(query) || userEmail.contains(query);
        }).toList();
      }
    });
  }

  Future<void> fetchPlaylists() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedPlaylists = await _adminPlaylistService.getAllPlaylistsForAdmin(
        page: currentPage,
        limit: limit,
      );
      setState(() {
        playlists = fetchedPlaylists;
        filteredPlaylists = fetchedPlaylists;
        totalCount = fetchedPlaylists.length; // Cần cập nhật nếu API trả về counts
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> createPlaylist(Map<String, dynamic> playlistData, File? coverFile) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _playlistService.createPlaylist(
        title: playlistData['title'],
        userId: playlistData['user'],
        coverImagePath: coverFile?.path,
        isPublic: playlistData['isPublic'],
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo playlist thành công')),
      );
      fetchPlaylists();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void showCreatePlaylistDialog() {
    final titleController = TextEditingController();
    final userController = TextEditingController();
    bool isPublic = true;
    File? coverFile;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo playlist mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Tên playlist',
                  hintText: 'Nhập tên playlist',
                  prefixIcon: const Icon(Icons.playlist_play, color: Color(0xFF0984E3)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDFE6E9)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0984E3)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: userController,
                decoration: InputDecoration(
                  labelText: 'ID người dùng',
                  hintText: 'Nhập ID người dùng',
                  prefixIcon: const Icon(Icons.person, color: Color(0xFF0984E3)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDFE6E9)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0984E3)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDFE6E9)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text('Công khai'),
                  subtitle: Text(
                    isPublic ? 'Mọi người có thể xem playlist này' : 'Chỉ người tạo có thể xem playlist này',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: isPublic,
                  activeColor: const Color(0xFF0984E3),
                  onChanged: (value) {
                    setState(() {
                      isPublic = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null) {
                    coverFile = File(result.files.single.path!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã chọn ảnh bìa')),
                    );
                  }
                },
                icon: const Icon(Icons.image),
                label: const Text('Chọn ảnh bìa'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                  backgroundColor: const Color(0xFF0984E3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty || userController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
                );
                return;
              }
              final playlistData = {
                'title': titleController.text,
                'user': userController.text,
                'isPublic': isPublic,
              };
              createPlaylist(playlistData, coverFile);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0984E3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Quản lý Playlist',
          style: TextStyle(
            color: Color(0xFF2D3436),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0984E3)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF0984E3)),
            tooltip: 'Thêm playlist',
            onPressed: showCreatePlaylistDialog,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(screenWidth * 0.04, 0, screenWidth * 0.04, 0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên hoặc email người dùng',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF0984E3)),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
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
                      : filteredPlaylists.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.playlist_play, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text(
                                  'Không tìm thấy playlist nào',
                                  style: TextStyle(fontSize: 18, color: Color(0xFF636E72)),
                                ),
                              ],
                            )
                          : ListView.separated(
                              itemCount: filteredPlaylists.length,
                              separatorBuilder: (context, idx) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final entry = filteredPlaylists[index];
                                final playlist = entry['playlist'] as Playlist;
                                final userName = entry['userName'] as String;
                                return Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: InkWell(
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/admin/playlist/:pid',
                                      arguments: playlist.id,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: (playlist.coverImageURL?.isNotEmpty ?? false)
                                                ? Image.network(
                                                    playlist.coverImageURL!,
                                                    width: 56,
                                                    height: 56,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => Container(
                                                      width: 56,
                                                      height: 56,
                                                      color: Colors.grey[200],
                                                      child: const Icon(Icons.music_note),
                                                    ),
                                                  )
                                                : Container(
                                                    width: 56,
                                                    height: 56,
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.music_note),
                                                  ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  playlist.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color(0xFF2D3436),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Người tạo: $userName',
                                                  style: const TextStyle(
                                                    color: Color(0xFF636E72),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.music_note,
                                                      size: 16,
                                                      color: const Color(0xFF0984E3),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${playlist.songs.length} bài hát',
                                                      style: const TextStyle(
                                                        color: Color(0xFF0984E3),
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Icon(
                                                      Icons.calendar_today,
                                                      size: 16,
                                                      color: const Color(0xFF636E72),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Tạo ngày ${playlist.createdAt.day}/${playlist.createdAt.month}/${playlist.createdAt.year}',
                                                      style: const TextStyle(
                                                        color: Color(0xFF636E72),
                                                        fontSize: 14,
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
                                              color: playlist.isPublic ? const Color(0xFF0984E3).withOpacity(0.1) : const Color(0xFF636E72).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  playlist.isPublic ? Icons.public : Icons.lock,
                                                  size: 16,
                                                  color: playlist.isPublic ? const Color(0xFF0984E3) : const Color(0xFF636E72),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  playlist.isPublic ? 'Công khai' : 'Riêng tư',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: playlist.isPublic ? const Color(0xFF0984E3) : const Color(0xFF636E72),
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: currentPage > 1
                        ? () {
                            setState(() {
                              currentPage--;
                            });
                            fetchPlaylists();
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
                            fetchPlaylists();
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
    );
  }
}