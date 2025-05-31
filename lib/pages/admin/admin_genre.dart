import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
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
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final fetchedGenres = await _genreService.getAllGenres(
        page: currentPage,
        limit: limit,
        title: _searchController.text.isNotEmpty ? _searchController.text : null,
        token: userProvider.user?.token,
      );
      setState(() {
        genres = fetchedGenres;
        filteredGenres = fetchedGenres;
        totalCount = fetchedGenres.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> createGenre(Map<String, dynamic> genreData, PlatformFile? coverFile) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _genreService.createGenre(
        title: genreData['title'],
        description: genreData['description'],
        coverImageFile: coverFile,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo thể loại thành công')),
      );
      fetchGenres();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updateGenre(String genreId, Map<String, dynamic> genreData, PlatformFile? coverFile) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _genreService.updateGenre(
        genreId: genreId,
        title: genreData['title'],
        description: '',
        coverImageFile: coverFile, // Truyền PlatformFile thay vì path
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
    final descriptionController = TextEditingController();
    PlatformFile? coverFile;

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
                decoration: const InputDecoration(
                  labelText: 'Tên thể loại',
                  hintText: 'Nhập tên thể loại',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Nhập mô tả thể loại',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                    allowMultiple: false,
                  );
                  if (result != null) {
                    coverFile = result.files.single;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã chọn ảnh bìa')),
                    );
                  }
                },
                icon: const Icon(Icons.image),
                label: const Text('Chọn ảnh bìa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
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
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên thể loại')),
                );
                return;
              }
              if (descriptionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập mô tả thể loại')),
                );
                return;
              }
              final genreData = {
                'title': titleController.text,
                'description': descriptionController.text,
              };
              createGenre(genreData, coverFile);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void showEditGenreDialog(Genre genre) {
    final titleController = TextEditingController(text: genre.title);
    PlatformFile? coverFile;

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
                    coverFile = result.files.single; // Lưu PlatformFile
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
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tiêu đề thể loại',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF0984E3)),
                  filled: true,
                  fillColor: Colors.white,
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
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0984E3))))
                  : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'Lỗi: $errorMessage',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        )
                      : filteredGenres.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.category, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Không có thể loại nào',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredGenres.length,
                              separatorBuilder: (context, idx) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final entry = filteredGenres[index];
                                final genre = entry['genre'] as Genre;
                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      if (genre.id.isNotEmpty) {
                                        Navigator.pushNamed(
                                          context,
                                          '/admin/genre/:gid',
                                          arguments: genre.id,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Invalid genre ID')),
                                        );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Hero(
                                            tag: 'genre-${genre.id}',
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: (genre.coverImage.isNotEmpty)
                                                  ? Image.network(
                                                      genre.coverImage,
                                                      width: 80,
                                                      height: 80,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        width: 80,
                                                        height: 80,
                                                        color: Colors.grey[200],
                                                        child: Icon(
                                                          Icons.category,
                                                          size: 32,
                                                          color: Colors.grey[400],
                                                        ),
                                                      ),
                                                    )
                                                  : Container(
                                                      width: 80,
                                                      height: 80,
                                                      color: Colors.grey[200],
                                                      child: Icon(
                                                        Icons.category,
                                                        size: 32,
                                                        color: Colors.grey[400],
                                                      ),
                                                    ),
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
                                                    fontSize: 18,
                                                    color: Color(0xFF2D3436),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  genre.description,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.music_note,
                                                      size: 16,
                                                      color: Theme.of(context).primaryColor,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${entry['songCount']} bài hát',
                                                      style: TextStyle(
                                                        color: Theme.of(context).primaryColor,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined),
                                            color: Theme.of(context).primaryColor,
                                            onPressed: () => showEditGenreDialog(genre),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline),
                                            color: Colors.red,
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Xác nhận xóa'),
                                                  content: Text('Bạn có chắc chắn muốn xóa thể loại "${genre.title}"?'),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(15),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text('Hủy'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        deleteGenre(genre.id);
                                                        Navigator.pop(context);
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.red,
                                                        foregroundColor: Colors.white,
                                                      ),
                                                      child: const Text('Xóa'),
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
            if (!isLoading && filteredGenres.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
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
                      color: currentPage > 1 ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Trang $currentPage / ${(totalCount / limit).ceil()}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                      color: currentPage < (totalCount / limit).ceil()
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
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