import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/user_provider.dart';
import '../../service/admin/admin_genre_service.dart';
import '../../widgets/client/genre_card.dart';
import '../../models/genre.dart';

class AdminGenrePage extends StatefulWidget {
  const AdminGenrePage({super.key});

  @override
  _AdminGenrePageState createState() => _AdminGenrePageState();
}

class _AdminGenrePageState extends State<AdminGenrePage> {
  final AdminGenreService _genreService = AdminGenreService();
  List<Map<String, dynamic>> genres = [];
  List<Map<String, dynamic>> filteredGenres = [];
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  int limit = 10;
  int totalCount = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchGenres();
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
        filteredGenres = genres;
      } else {
        filteredGenres = genres.where((entry) {
          final genre = entry['genre'] as Genre;
          return genre.title.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> fetchGenres() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedGenres = await _genreService.getAllGenres(
        page: currentPage,
        limit: limit,
        title: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
      setState(() {
        genres = fetchedGenres;
        filteredGenres = fetchedGenres;
        totalCount = fetchedGenres.length; // Cần cập nhật nếu API trả về counts
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> createGenre(Map<String, dynamic> genreData, File? coverFile) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _genreService.createGenre(
        title: genreData['title'],
        description: '',
        coverImagePath: coverFile?.path,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo thể loại thành công')),
      );
      fetchGenres();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> updateGenre(String genreId, Map<String, dynamic> genreData, File? coverFile) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _genreService.updateGenre(
        genreId: genreId,
        title: genreData['title'],
        description: '',
        coverImagePath: coverFile?.path,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thể loại thành công')),
      );
      fetchGenres();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> deleteGenre(String genreId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _genreService.deleteGenre(
        genreId: genreId,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa thể loại thành công')),
      );
      fetchGenres();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void showCreateGenreDialog() {
    final titleController = TextEditingController();
    File? coverFile;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo thể loại mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tên thể loại'),
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null) {
                    coverFile = File(result.files.single.path!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã chọn ảnh bìa')),
                    );
                  }
                },
                child: const Text('Chọn ảnh bìa'),
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
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên thể loại')),
                );
                return;
              }
              final genreData = {
                'title': titleController.text,
              };
              createGenre(genreData, coverFile);
              Navigator.pop(context);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void showEditGenreDialog(Genre genre) {
    final titleController = TextEditingController(text: genre.title);
    File? coverFile;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa thể loại'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tên thể loại'),
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null) {
                    coverFile = File(result.files.single.path!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã chọn ảnh bìa mới')),
                    );
                  }
                },
                child: const Text('Chọn ảnh bìa mới'),
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
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên thể loại')),
                );
                return;
              }
              final genreData = {
                'title': titleController.text,
              };
              updateGenre(genre.id, genreData, coverFile);
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
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
          'Quản lý Thể loại',
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
            tooltip: 'Thêm thể loại',
            onPressed: showCreateGenreDialog,
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
                  hintText: 'Tìm kiếm theo tiêu đề thể loại',
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
                  ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0984E3))))
                  : errorMessage != null
                      ? Center(child: Text('Lỗi: $errorMessage', style: const TextStyle(color: Colors.red)))
                      : filteredGenres.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.category, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text('Không có thể loại nào', style: TextStyle(fontSize: 18, color: Color(0xFF636E72))),
                              ],
                            )
                          : ListView.separated(
                              itemCount: filteredGenres.length,
                              separatorBuilder: (context, idx) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final entry = filteredGenres[index];
                                final genre = entry['genre'] as Genre;
                                return Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: (genre.coverImage.isNotEmpty)
                                              ? Image.network(
                                                  genre.coverImage,
                                                  width: 56,
                                                  height: 56,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    width: 56,
                                                    height: 56,
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.category),
                                                  ),
                                                )
                                              : Container(
                                                  width: 56,
                                                  height: 56,
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.category),
                                                ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                genre.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Color(0xFF2D3436),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Color(0xFF0984E3)),
                                          onPressed: () => showEditGenreDialog(genre),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
                                                content: Text('Bạn có chắc chắn muốn xóa thể loại "${genre.title}"?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Hủy'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      deleteGenre(genre.id);
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
                            fetchGenres();
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
                            fetchGenres();
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
    );
  }
}