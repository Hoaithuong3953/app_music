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
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = await userProvider.token;
      final userId = userProvider.user?.id;
      
      if (token == null) {
        throw Exception('Please log in to view your playlists');
      }

      if (userId == null) {
        throw Exception('User information not found');
      }

      final fetchedPlaylists = await _playlistService.getAllPlaylists(
        token: token,
        userId: userId,
      );
      
      if (!mounted) return;
      setState(() {
        playlists = fetchedPlaylists.map((playlist) {
          String ownerName = 'Unknown User';
          if (playlist.user != null) {
            if (playlist.user is User) {
              ownerName = (playlist.user as User).email ?? 'Unknown User';
            } else if (playlist.user is String) {
              ownerName = playlist.user.toString();
            }
          }
          return {
            'playlist': playlist,
            'ownerName': ownerName,
            'songCount': playlist.songs.length,
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _selectTab(String tab) {
    if (!mounted) return; // Kiểm tra mounted
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

        if (!mounted) return; // Kiểm tra mounted
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
    if (!mounted) return; // Kiểm tra mounted
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
        const SnackBar(content: Text('Please log in to create a playlist')),
      );
      return;
    }

    _titleController.clear();
    bool isPublic = true;
    if (!mounted) return;
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
              title: Row(
                children: [
                  Icon(Icons.playlist_add, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Create New Playlist',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Playlist Title',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        enabled: !_isCreating,
                        decoration: const InputDecoration(
                          hintText: 'Enter playlist title',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Cover Image (Optional)',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: GestureDetector(
                          onTap: _isCreating
                              ? null
                              : () async {
                                  await _pickImage();
                                  if (context.mounted) {
                                    setDialogState(() {});
                                  }
                                },
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  _selectedImage != null
                                      ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: 160,
                                          height: 160,
                                          errorBuilder: (context, error, stackTrace) {
                                            print('Error displaying image: $error');
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.error,
                                                    color: Colors.red,
                                                    size: 30,
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'Failed to load',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(color: Colors.red, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_a_photo,
                                                color: Theme.of(context).primaryColor,
                                                size: 40,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Add Cover Image\n(Recommended: 300x300)',
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Theme.of(context).primaryColor,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  if (_selectedImage != null)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: _isCreating
                                                ? null
                                                : () {
                                                    setDialogState(() {
                                                      _selectedImage = null;
                                                    });
                                                  },
                                            borderRadius: BorderRadius.circular(20),
                                            child: const Padding(
                                              padding: EdgeInsets.all(6),
                                              child: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Public Playlist',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Allow everyone to see this playlist',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: Switch(
                            value: isPublic,
                            onChanged: _isCreating
                                ? null
                                : (value) {
                                    setDialogState(() {
                                      isPublic = value;
                                    });
                                  },
                            activeColor: Theme.of(context).primaryColor,
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.grey[300],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: _isCreating
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isCreating
                      ? null
                      : () async {
                          final title = _titleController.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a playlist title')),
                            );
                            return;
                          }

                          if (title.toLowerCase() == 'favorite') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cannot create a playlist named "Favorite". Please choose a different name.'),
                              ),
                            );
                            setDialogState(() {
                              _isCreating = false;
                            });
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
                              isPublic: isPublic,
                              token: token,
                            );
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Playlist created successfully')),
                            );
                            await _fetchPlaylists();
                          } catch (e) {
                            String error = e.toString();
                            print('Error creating playlist: $error');
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
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 3,
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Create',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              elevation: 5,
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