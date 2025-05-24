import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/user_provider.dart';
import '../../service/admin/admin_artist_service.dart';
import '../../models/artist.dart';

class AdminArtistPage extends StatefulWidget {
  const AdminArtistPage({super.key});

  @override
  AdminArtistPageState createState() => AdminArtistPageState();
}

class AdminArtistPageState extends State<AdminArtistPage> {
  final AdminArtistService _artistService = AdminArtistService();
  List<Map<String, dynamic>> artists = [];
  List<Map<String, dynamic>> filteredArtists = [];
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  int limit = 10;
  int totalCount = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchArtists();
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
        filteredArtists = artists;
      } else {
        filteredArtists = artists.where((entry) {
          final artist = entry['artist'] as Artist;
          return artist.title.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> fetchArtists() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final fetchedArtists = await _artistService.getAllArtists(
        page: currentPage,
        limit: limit,
        title: _searchController.text.isNotEmpty ? _searchController.text : null,
        token: userProvider.user?.token,
      );
      setState(() {
        artists = fetchedArtists;
        filteredArtists = fetchedArtists;
        totalCount = fetchedArtists.isNotEmpty ? fetchedArtists[0]['counts'] ?? fetchedArtists.length : 0;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> createArtist(Map<String, dynamic> artistData, File? avatarFile) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _artistService.createArtist(
        title: artistData['title'],
        avatarPath: avatarFile?.path ?? '',
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nghệ sĩ được tạo thành công')),
      );
      fetchArtists();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> deleteArtist(String artistId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _artistService.deleteArtist(
        artistId: artistId,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nghệ sĩ đã được xóa thành công')),
      );
      fetchArtists();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void showCreateArtistDialog() {
    final titleController = TextEditingController();
    File? avatarFile;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo Nghệ sĩ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tên nghệ sĩ'),
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null) {
                    avatarFile = File(result.files.single.path!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ảnh đại diện đã được chọn')),
                    );
                  }
                },
                child: const Text('Chọn Ảnh Đại diện'),
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
              if (titleController.text.isEmpty || avatarFile == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tên và ảnh đại diện là bắt buộc')),
                );
                return;
              }
              final artistData = {
                'title': titleController.text,
              };
              createArtist(artistData, avatarFile);
              Navigator.pop(context);
            },
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
      appBar: AppBar(
        title: Text(
          'Quản lý Nghệ sĩ',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: screenHeight * 0.025,
                color: Colors.black,
              ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm nghệ sĩ',
            onPressed: showCreateArtistDialog,
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: EdgeInsets.fromLTRB(screenWidth * 0.04, 0, screenWidth * 0.04, 0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Tìm kiếm theo tên nghệ sĩ',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                        ? Center(child: Text('Lỗi: $errorMessage'))
                        : filteredArtists.isEmpty
                            ? const Center(child: Text('Không tìm thấy nghệ sĩ'))
                            : ListView.builder(
                                itemCount: filteredArtists.length,
                                itemBuilder: (context, index) {
                                  final entry = filteredArtists[index];
                                  final artist = entry['artist'] as Artist;
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => Navigator.pushNamed(
                                            context,
                                            '/admin/artist/:id', // Sửa tuyến
                                            arguments: {'id': artist.id}, // Truyền arguments đúng cách
                                          ),
                                          child: ArtistCard(artist: artist),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Xác nhận Xóa'),
                                              content: Text('Bạn có chắc muốn xóa ${artist.title}?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Hủy'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    deleteArtist(artist.id);
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('Xóa'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
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
                              fetchArtists();
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
                              fetchArtists();
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
      ),
    );
  }
}

class ArtistCard extends StatelessWidget {
  final Artist artist;

  const ArtistCard({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: artist.avatar != null ? NetworkImage(artist.avatar!) : null,
          child: artist.avatar == null ? Text(artist.title[0]) : null,
        ),
        title: Text(artist.title),
      ),
    );
  }
}