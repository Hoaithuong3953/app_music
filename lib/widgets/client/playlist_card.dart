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
  final VoidCallback? onTap; // Thêm tham số onTap

  const PlaylistCard({
    required this.playlist,
    required this.ownerName,
    required this.songCount,
    this.onPlaylistUpdated,
    this.onTap, // Thêm vào constructor
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
          title: Text('Edit Playlist'),
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
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                final title = _titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a playlist title')),
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
                    SnackBar(content: Text('Playlist updated successfully')),
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
          title: Text('Delete Playlist'),
          content: Text('Are you sure you want to delete "${widget.playlist.title}"?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                try {
                  await _playlistService.deletePlaylist(
                    playlistId: widget.playlist.id,
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Playlist deleted successfully')),
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

    final iconSize = screenWidth * 0.12;

    return Card(
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      color: const Color(0xFFE0E0E0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: screenHeight * 0.08,
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.005,
          ),
          leading: Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
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
          title: Text(
            widget.playlist.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: screenHeight * 0.02,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          subtitle: Opacity(
            opacity: 0.6,
            child: Text(
              widget.ownerName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: screenHeight * 0.018,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              size: screenHeight * 0.025,
              color: Theme.of(context).highlightColor,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditPlaylistDialog(context);
              } else if (value == 'delete') {
                _showDeleteConfirmationDialog(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'edit',
                child: Text('Edit'),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
          onTap: widget.onTap, // Áp dụng onTap cho ListTile
        ),
      ),
    );
  }
}