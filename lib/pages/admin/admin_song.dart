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
      appBar: AppBar(
        title: Text(
          'Quản lý Bài hát',
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
            tooltip: 'Thêm bài hát',
            onPressed: showCreateSongDialog,
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
                    labelText: 'Tìm kiếm theo tiêu đề hoặc nghệ sĩ',
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
                        : filteredSongs.isEmpty
                            ? const Center(child: Text('No songs found'))
                            : ListView.builder(
                                itemCount: filteredSongs.length,
                                itemBuilder: (context, index) {
                                  final entry = filteredSongs[index];
                                  final song = entry['song'] as Song;
                                  final artistName = entry['artistName'] as String;
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: SongTile(
                                          song: song,
                                          artistName: artistName,
                                          index: index + 1,
                                          onTap: () => Navigator.pushNamed(
                                            context,
                                            '/admin/song/:sid',
                                            arguments: song.id,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => showEditSongDialog(entry),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Confirm Delete'),
                                              content: Text('Are you sure you want to delete ${song.title}?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    deleteSong(song.id);
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
                              fetchSongs();
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
                              fetchSongs();
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