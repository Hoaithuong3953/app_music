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
  const LibraryPage({Key? key}) : super(key: key);

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
  bool _isCreating = false;

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
                ? (playlist.user as User).email ?? 'Unknown User'
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
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        print('Picked image path: ${file.path}');

        // Kiểm tra định dạng ảnh (JPG, JPEG, PNG)
        final allowedExtensions = ['.jpg', '.jpeg', '.png'];
        final fileExtension = pickedFile.path.toLowerCase().split('.').last;
        if (!allowedExtensions.contains('.$fileExtension')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select a JPG, JPEG, or PNG image')),
          );
          return;
        }

        // Kiểm tra kích thước ảnh (giới hạn 5MB)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) { // 5MB
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image size must be less than 5MB')),
          );
          return;
        }

        setState(() {
          _selectedImage = file;
          print('Updated _selectedImage: $_selectedImage');
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image. Please try again.')),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
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
      _isCreating = false;
    });

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
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
                      onTap: _isCreating
                          ? null
                          : () async {
                        await _pickImage();
                        if (context.mounted) {
                          setDialogState(() {});
                        }
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _selectedImage != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error displaying image: $error');
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 30,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Failed to load image',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.red, fontSize: 12),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            )
                                : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  color: Colors.grey,
                                  size: 30,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Select Cover Image',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedImage != null)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isCreating
                                    ? null
                                    : () {
                                  setDialogState(() {
                                    _selectedImage = null;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: _isCreating
                      ? null
                      : () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _isCreating ? Colors.grey : Theme.of(context).primaryColor,
                  ),
                ),
                TextButton(
                  child: _isCreating
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text('Create'),
                  onPressed: _isCreating
                      ? null
                      : () async {
                    final title = _titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a playlist title')),
                      );
                      return;
                    }

                    setDialogState(() {
                      _isCreating = true;
                    });

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
                      String error = e.toString();
                      if (error.contains('No access token found')) {
                        error = 'Please log in to create a playlist';
                      } else if (error.contains('Failed to create playlist')) {
                        error = 'Failed to create playlist. Please try again.';
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    } finally {
                      if (context.mounted) {
                        setDialogState(() {
                          _isCreating = false;
                        });
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _isCreating ? Colors.grey : Theme.of(context).primaryColor,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
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
                      onPressed: () {
                        Navigator.of(context).pushNamed('/search');
                      },
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
                      // Sử dụng Navigator con của MainPage.dart
                      Navigator.of(context).pushNamed(
                        '/playlist-detail',
                        arguments: {'playlistId': playlist.id},
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
    );
  }
}