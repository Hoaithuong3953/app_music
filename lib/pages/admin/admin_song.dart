import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/user_provider.dart';
import '../../service/client/song_service.dart';
import '../../models/song.dart';
import '../../widgets/client/song_tile.dart';

class AdminSongPage extends StatefulWidget {
  const AdminSongPage({super.key});

  @override
  _AdminSongPageState createState() => _AdminSongPageState();
}

class _AdminSongPageState extends State<AdminSongPage> {
  final SongService _songService = SongService();
  List<Map<String, dynamic>> songs = [];
  List<Map<String, dynamic>> filteredSongs = [];
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  int limit = 10;
  int totalCount = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSongs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        filteredSongs = songs;
      });
      fetchSongs();
    } else {
      fetchSongs(searchQuery: query);
    }
  }

  Future<void> fetchSongs({String? searchQuery}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedSongs = await _songService.getAllSongs(
        page: currentPage,
        limit: limit,
        title: searchQuery,
      );
      setState(() {
        songs = fetchedSongs;
        filteredSongs = fetchedSongs;
        totalCount = fetchedSongs.length; // Cần cập nhật nếu API trả về counts
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> deleteSong(String songId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final response = await http.delete(
        Uri.parse('http://localhost:8080/api/v1/song/$songId'),
        headers: {
          'Authorization': 'Bearer ${userProvider.user?.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song deleted successfully')),
        );
        fetchSongs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete song')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> createSong(Map<String, dynamic> songData, File? songFile, File? coverFile) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8080/api/v1/song'),
      );

      request.headers['Authorization'] = 'Bearer ${userProvider.user?.token}';

      songData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      if (songFile != null) {
        request.files.add(await http.MultipartFile.fromPath('song', songFile.path));
      }

      if (coverFile != null) {
        request.files.add(await http.MultipartFile.fromPath('cover', coverFile.path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song created successfully')),
        );
        fetchSongs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create song: $responseBody')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> updateSong(String songId, Map<String, dynamic> songData, File? songFile, File? coverFile) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('http://localhost:8080/api/v1/song/$songId'),
      );

      request.headers['Authorization'] = 'Bearer ${userProvider.user?.token}';

      songData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      if (songFile != null) {
        request.files.add(await http.MultipartFile.fromPath('song', songFile.path));
      }

      if (coverFile != null) {
        request.files.add(await http.MultipartFile.fromPath('cover', coverFile.path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song updated successfully')),
        );
        fetchSongs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update song: $responseBody')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void showCreateSongDialog() {
    final titleController = TextEditingController();
    final artistController = TextEditingController();
    final genreController = TextEditingController();
    File? songFile;
    File? coverFile;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Song'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: artistController,
                decoration: const InputDecoration(labelText: 'Artist ID'),
              ),
              TextField(
                controller: genreController,
                decoration: const InputDecoration(labelText: 'Genre IDs (comma-separated)'),
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
                  if (result != null) {
                    songFile = File(result.files.single.path!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Song file selected')),
                    );
                  }
                },
                child: const Text('Select Song File'),
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null) {
                    coverFile = File(result.files.single.path!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cover image selected')),
                    );
                  }
                },
                child: const Text('Select Cover Image'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isEmpty || songFile == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title and song file are required')),
                );
                return;
              }
              final songData = {
                'title': titleController.text,
                'artist': artistController.text,
                'genre': genreController.text,
              };
              createSong(songData, songFile, coverFile);
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void showEditSongDialog(dynamic song) {
    final titleController = TextEditingController(text: song['title']);
    final artistController = TextEditingController(text: song['artist']?['_id']?.toString() ?? '');
    final genreController = TextEditingController(
        text: song['genre']?.map((g) => g['_id']?.toString() ?? '').join(',') ?? '');
    File? songFile;
    File? coverFile;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Song'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: artistController,
                decoration: const InputDecoration(labelText: 'Artist ID'),
              ),
              TextField(
                controller: genreController,
                decoration: const InputDecoration(labelText: 'Genre IDs (comma-separated)'),
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
                  if (result != null) {
                    songFile = File(result.files.single.path!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Song file selected')),
                    );
                  }
                },
                child: const Text('Select New Song File'),
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null) {
                    coverFile = File(result.files.single.path!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cover image selected')),
                    );
                  }
                },
                child: const Text('Select New Cover Image'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title is required')),
                );
                return;
              }
              final songData = {
                'title': titleController.text,
                'artist': artistController.text,
                'genre': genreController.text,
              };
              updateSong(song['_id'], songData, songFile, coverFile);
              Navigator.pop(context);
            },
            child: const Text('Save'),
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
          'Quản lý Bài hát',
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
            tooltip: 'Thêm bài hát',
            onPressed: showCreateSongDialog,
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
                  hintText: 'Tìm kiếm theo tên bài hát',
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
                      : filteredSongs.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.music_note, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text(
                                  'Không tìm thấy bài hát nào',
                                  style: TextStyle(fontSize: 18, color: Color(0xFF636E72)),
                                ),
                              ],
                            )
                          : ListView.separated(
                              itemCount: filteredSongs.length,
                              separatorBuilder: (context, idx) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final entry = filteredSongs[index];
                                final song = entry['song'] as Song;
                                final artistName = entry['artistName'] as String?;
                                final genreNames = entry['genreNames'] as List<String>?;
                                return Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: InkWell(
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/admin/song/:sid',
                                      arguments: song.id,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: (song.coverImage?.isNotEmpty ?? false)
                                                ? Image.network(
                                                    song.coverImage!,
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
                                                  song.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color(0xFF2D3436),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                if (artistName != null)
                                                  Text(
                                                    'Nghệ sĩ: $artistName',
                                                    style: const TextStyle(
                                                      color: Color(0xFF636E72),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    if (genreNames != null && genreNames.isNotEmpty) ...[
                                                      Icon(
                                                        Icons.category,
                                                        size: 16,
                                                        color: const Color(0xFF0984E3),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        genreNames.join(', '),
                                                        style: const TextStyle(
                                                          color: Color(0xFF0984E3),
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                    ],
                                                    Icon(
                                                      Icons.calendar_today,
                                                      size: 16,
                                                      color: const Color(0xFF636E72),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Tạo ngày ${song.createdAt.day}/${song.createdAt.month}/${song.createdAt.year}',
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
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Color(0xFF0984E3)),
                                            onPressed: () => showEditSongDialog(song),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                  title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  content: Text('Bạn có chắc chắn muốn xóa bài hát "${song.title}"?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text('Hủy'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        deleteSong(song.id);
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text('Xóa', style: TextStyle(color: Color(0xFFE74C3C))),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
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
                            fetchSongs();
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
                            fetchSongs();
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