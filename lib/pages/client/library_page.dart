import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/user.dart';
import '../../widgets/client/playlist_card.dart';
import '../../models/playlist.dart';
import '../../service/client/playlist_service.dart';
import '../../providers/user_provider.dart';

class LibraryPage extends StatefulWidget {
  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final PlaylistService _playlistService = PlaylistService();
  String? _selectedTab;
  List<Map<String, dynamic>> playlists = [];
  bool isLoading = true;
  String? errorMessage;
  final TextEditingController _titleController = TextEditingController();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _fetchPlaylists();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlaylists() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedPlaylists = await _playlistService.getAllPlaylists();
      setState(() {
        playlists = fetchedPlaylists.map((playlist) {
          return {
            'playlist': playlist,
            'ownerName': playlist.user is User
                ? (playlist.user as User).email ?? 'Unknown User' // Sử dụng email
                : 'Unknown User',
            'songCount': playlist.songs.length,
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _selectTab(String tab) {
    setState(() {
      _selectedTab = (_selectedTab == tab) ? null : tab;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    final token = await userProvider.token;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to create a playlist')),
      );
      return;
    }

    _titleController.clear();
    setState(() {
      _selectedImage = null;
    });

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create New Playlist'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Playlist Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _selectedImage != null
                        ? Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    )
                        : Center(
                      child: Text(
                        'Select Cover Image',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Create'),
              onPressed: () async {
                final title = _titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a playlist title')),
                  );
                  return;
                }

                try {
                  await _playlistService.createPlaylist(
                    title: title,
                    userId: userId,
                    coverImagePath: _selectedImage?.path,
                    token: token,
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Playlist created successfully')),
                  );
                  await _fetchPlaylists();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating playlist: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: EdgeInsets.fromLTRB(screenWidth * 0.04, screenHeight * 0.03, screenWidth * 0.04, 0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Library',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: screenHeight * 0.035,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            size: screenHeight * 0.03,
                            color: Theme.of(context).highlightColor,
                          ),
                          onPressed: _fetchPlaylists,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.search,
                            size: screenHeight * 0.03,
                            color: Theme.of(context).highlightColor,
                          ),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add,
                            size: screenHeight * 0.03,
                            color: Theme.of(context).highlightColor,
                          ),
                          onPressed: () {
                            _showCreatePlaylistDialog(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : errorMessage != null
                    ? Center(child: Text('Error: $errorMessage'))
                    : playlists.isEmpty
                    ? Center(child: Text('No playlists available'))
                    : Column(
                  children: playlists.map(
                        (data) {
                      final playlist = data['playlist'] as Playlist;
                      final ownerName = data['ownerName'] as String;
                      final songCount = data['songCount'] as int;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/playlist-detail',
                            arguments: {
                              'playlistId': playlist.id,
                            },
                          );
                        },
                        child: PlaylistCard(
                          playlist: playlist,
                          ownerName: ownerName,
                          songCount: songCount,
                          onPlaylistUpdated: _fetchPlaylists,
                        ),
                      );
                    },
                  ).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}