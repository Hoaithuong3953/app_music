import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/playlist.dart';
import '../../service/client/playlist_service.dart';

class PlaylistCard extends StatefulWidget {
  final Playlist playlist;
  final String ownerName;
  final int songCount;
  final VoidCallback? onPlaylistUpdated;
  final VoidCallback? onTap;

  const PlaylistCard({
    required this.playlist,
    required this.ownerName,
    required this.songCount,
    this.onPlaylistUpdated,
    this.onTap,
    super.key,
  });

  @override
  _PlaylistCardState createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<PlaylistCard> {
  final PlaylistService _playlistService = PlaylistService();
  final TextEditingController _titleController = TextEditingController();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.playlist.title;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
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

  Future<void> _showEditPlaylistDialog(BuildContext context) async {
    _titleController.text = widget.playlist.title;
    setState(() {
      _selectedImage = null;
    });

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Playlist'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Playlist Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
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
                        : widget.playlist.coverImageURL != null &&
                                widget.playlist.coverImageURL != 'https://example.com/default-cover.jpg'
                            ? Image.network(
                                widget.playlist.coverImageURL!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Image.asset(
                                  'images/default_cover.jpg',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                'images/default_cover.jpg',
                                fit: BoxFit.cover,
                              ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                final title = _titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a playlist title')),
                  );
                  return;
                }

                try {
                  await _playlistService.updatePlaylist(
                    playlistId: widget.playlist.id,
                    title: title,
                    coverImagePath: _selectedImage?.path,
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist updated successfully')),
                  );
                  if (widget.onPlaylistUpdated != null) {
                    widget.onPlaylistUpdated!();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating playlist: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Playlist'),
          content: Text('Are you sure you want to delete "${widget.playlist.title}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                try {
                  await _playlistService.deletePlaylist(
                    playlistId: widget.playlist.id,
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist deleted successfully')),
                  );
                  if (widget.onPlaylistUpdated != null) {
                    widget.onPlaylistUpdated!();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting playlist: $e')),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenHeight * 0.015,
      ),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(15),
        splashColor: Theme.of(context).highlightColor.withOpacity(0.2),
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.03),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [
                Colors.grey[800]!,
                Colors.grey[900]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              // Ảnh bìa playlist
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: screenWidth * 0.15,
                  height: screenWidth * 0.15,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                  ),
                  child: widget.playlist.coverImageURL != null &&
                          widget.playlist.coverImageURL != 'https://example.com/default-cover.jpg'
                      ? Image.network(
                          widget.playlist.coverImageURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'images/default_cover.jpg',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'images/default_cover.jpg',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              // Thông tin playlist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.playlist.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: screenHeight * 0.022,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Opacity(
                      opacity: 0.7,
                      child: Text(
                        '${widget.ownerName} • ${widget.songCount} songs',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: screenHeight * 0.016,
                              color: Colors.white70,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              // Nút menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: screenHeight * 0.025,
                  color: Colors.white,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditPlaylistDialog(context);
                  } else if (value == 'delete') {
                    _showDeleteConfirmationDialog(context);
                  } else if (value == 'update_img') {
                    _pickImage();
                  }
                },
                itemBuilder: (BuildContext context) {
                  final isFavorite = widget.playlist.title == 'Favorite';
                  if (isFavorite) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'update_img',
                        child: Text('Update Image'),
                      ),
                    ];
                  } else {
                    return [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ];
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}