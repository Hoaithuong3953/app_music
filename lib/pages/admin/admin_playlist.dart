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
        const SnackBar(content: Text('Playlist created successfully')),
      );
      fetchPlaylists();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
        title: const Text('Create Playlist'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: userController,
                decoration: const InputDecoration(labelText: 'User ID'),
              ),
              SwitchListTile(
                title: const Text('Public'),
                value: isPublic,
                onChanged: (value) {
                  setState(() {
                    isPublic = value;
                  });
                },
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
              if (titleController.text.isEmpty || userController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title and User ID are required')),
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
            child: const Text('Create'),
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
          'Quản lý Playlist',
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
            tooltip: 'Thêm playlist',
            onPressed: showCreatePlaylistDialog,
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
                    labelText: 'Tìm kiếm theo user (tên hoặc email)',
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
                        : filteredPlaylists.isEmpty
                            ? const Center(child: Text('No playlists found'))
                            : ListView.builder(
                                itemCount: filteredPlaylists.length,
                                itemBuilder: (context, index) {
                                  final entry = filteredPlaylists[index];
                                  final playlist = entry['playlist'] as Playlist;
                                  final userName = entry['userName'] as String;
                                  return PlaylistCard(
                                    playlist: playlist,
                                    ownerName: userName,
                                    songCount: playlist.songs.length,
                                    onPlaylistUpdated: fetchPlaylists,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/admin/playlist/:pid',
                                      arguments: playlist.id,
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
                              fetchPlaylists();
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
                              fetchPlaylists();
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