import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/user_provider.dart';
import '../../service/admin/admin_album_service.dart';
import '../../widgets/client/album_card.dart';
import '../../models/album.dart';

class AdminAlbumPage extends StatefulWidget {
  const AdminAlbumPage({super.key});

  @override
  _AdminAlbumPageState createState() => _AdminAlbumPageState();
}

class _AdminAlbumPageState extends State<AdminAlbumPage> {
  final AdminAlbumService _albumService = AdminAlbumService();
  List<Map<String, dynamic>> albums = [];
  List<Map<String, dynamic>> filteredAlbums = [];
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  int limit = 10;
  int totalCount = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAlbums();
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
        filteredAlbums = albums;
      } else {
        filteredAlbums = albums.where((entry) {
          final album = entry['album'] as Album;
          return album.title.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> fetchAlbums() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedAlbums = await _albumService.getAllAlbums(
        page: currentPage,
        limit: limit,
        title: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
      setState(() {
        albums = fetchedAlbums;
        filteredAlbums = fetchedAlbums;
        totalCount = fetchedAlbums.length; // Cần cập nhật nếu API trả về counts
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> createAlbum(Map<String, dynamic> albumData, File? coverFile) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _albumService.createAlbum(
        title: albumData['title'],
        artistId: albumData['artist'],
        genreId: albumData['genre'],
        coverImagePath: coverFile?.path,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album created successfully')),
      );
      fetchAlbums();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> updateAlbum(String albumId, Map<String, dynamic> albumData, File? coverFile) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _albumService.updateAlbum(
        albumId: albumId,
        title: albumData['title'],
        artistId: albumData['artist'],
        genreId: albumData['genre'],
        coverImagePath: coverFile?.path,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album updated successfully')),
      );
      fetchAlbums();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> deleteAlbum(String albumId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _albumService.deleteAlbum(
        albumId: albumId,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album deleted successfully')),
      );
      fetchAlbums();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void showCreateAlbumDialog() {
    final titleController = TextEditingController();
    final artistController = TextEditingController();
    final genreController = TextEditingController();
    File? coverFile;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Album'),
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
                decoration: const InputDecoration(labelText: 'Genre ID'),
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
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title is required')),
                );
                return;
              }
              final albumData = {
                'title': titleController.text,
                'artist': artistController.text.isNotEmpty ? artistController.text : null,
                'genre': genreController.text.isNotEmpty ? genreController.text : null,
              };
              createAlbum(albumData, coverFile);
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void showEditAlbumDialog(Album album) {
    final titleController = TextEditingController(text: album.title);
    final artistController = TextEditingController(text: album.artist ?? '');
    final genreController = TextEditingController(text: album.genre ?? '');
    File? coverFile;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Album'),
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
                decoration: const InputDecoration(labelText: 'Genre ID'),
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
              final albumData = {
                'title': titleController.text,
                'artist': artistController.text.isNotEmpty ? artistController.text : null,
                'genre': genreController.text.isNotEmpty ? genreController.text : null,
              };
              updateAlbum(album.id, albumData, coverFile);
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
      appBar: AppBar(
        title: Text(
          'Quản lý Album',
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
            tooltip: 'Thêm album',
            onPressed: showCreateAlbumDialog,
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
                    labelText: 'Tìm kiếm theo tiêu đề album',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                        ? Center(child: Text('Error: $errorMessage'))
                        : filteredAlbums.isEmpty
                            ? const Center(child: Text('No albums found'))
                            : ListView.builder(
                                itemCount: filteredAlbums.length,
                                itemBuilder: (context, index) {
                                  final entry = filteredAlbums[index];
                                  final album = entry['album'] as Album;
                                  final artistName = entry['artistName'] as String;
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => Navigator.pushNamed(
                                            context,
                                            '/admin/album/:aid',
                                            arguments: album.id,
                                          ),
                                          child: AlbumCard(
                                            album: album,
                                            artistName: artistName,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => showEditAlbumDialog(album),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Confirm Delete'),
                                              content: Text('Are you sure you want to delete ${album.title}?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    deleteAlbum(album.id);
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('Delete'),
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
                              fetchAlbums();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('Page $currentPage / ${(totalCount / limit).ceil()}'),
                    IconButton(
                      onPressed: currentPage < (totalCount / limit).ceil()
                          ? () {
                              setState(() {
                                currentPage++;
                              });
                              fetchAlbums();
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