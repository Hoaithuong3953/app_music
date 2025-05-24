import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_client.dart';
import '../../service/client/playlist_service.dart';
import '../../service/client/song_service.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../widgets/client/song_tile.dart';
import '../../providers/user_provider.dart';

class AdminShowPlaylistPage extends StatefulWidget {
  final String playlistId;

  const AdminShowPlaylistPage({super.key, required this.playlistId});

  @override
  _AdminShowPlaylistPageState createState() => _AdminShowPlaylistPageState();
}

class _AdminShowPlaylistPageState extends State<AdminShowPlaylistPage> {
  Playlist? playlist;
  List<Map<String, dynamic>> songs = [];
  String? userName;
  bool isLoading = true;
  final PlaylistService _playlistService = PlaylistService();
  final SongService _songService = SongService();
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    fetchPlaylistDetails();
  }

  Future<void> fetchPlaylistDetails() async {
    try {
      final fetchedPlaylist = await _playlistService.getPlaylist(widget.playlistId);
      final fetchedSongs = fetchedPlaylist.songs.map((song) {
        return {
          'song': song,
          'artistName': song.artist ?? 'Unknown Artist',
        };
      }).toList();
      final userData = fetchedPlaylist.user is Map<String, dynamic>
          ? fetchedPlaylist.user as Map<String, dynamic>
          : null;
      setState(() {
        playlist = fetchedPlaylist;
        songs = fetchedSongs;
        userName = userData != null
            ? '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim()
            : 'Unknown User';
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deletePlaylist() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _playlistService.deletePlaylist(
        playlistId: widget.playlistId,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist deleted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> addSongsToPlaylist() async {
    final allSongs = await _songService.getAllSongs();
    final selectedSongIds = <String>[];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Songs to Playlist'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: allSongs.map((entry) {
                final song = entry['song'] as Song;
                return CheckboxListTile(
                  title: Text(song.title),
                  subtitle: Text(entry['artistName']),
                  value: selectedSongIds.contains(song.id),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedSongIds.add(song.id);
                      } else {
                        selectedSongIds.remove(song.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (selectedSongIds.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select at least one song')),
                );
                return;
              }
              try {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await _playlistService.addSongsToPlaylist(
                  playlistId: widget.playlistId,
                  songIds: selectedSongIds,
                  token: userProvider.user?.token,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Songs added successfully')),
                );
                Navigator.pop(context);
                fetchPlaylistDetails();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> removeSongFromPlaylist(String songId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final updatedSongIds = playlist!.songs.map((song) => song.id).toList()..remove(songId);
      final response = await _apiClient.put(
        'playlist/${widget.playlistId}',
        {'songs': updatedSongIds.join(',')},
        token: userProvider.user?.token,
      );
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song removed successfully')),
        );
        fetchPlaylistDetails();
      } else {
        throw Exception(response['message'] ?? 'Failed to remove song');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist != null ? playlist!.title : 'Playlist Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addSongsToPlaylist,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: playlist != null
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: Text('Are you sure you want to delete ${playlist!.title}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              deletePlaylist();
                              Navigator.pop(context);
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : playlist == null
              ? const Center(child: Text('Failed to load playlist'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (playlist!.coverImageURL != null)
                        Center(
                          child: Image.network(
                            playlist!.coverImageURL!,
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text('Title: ${playlist!.title}', style: const TextStyle(fontSize: 16)),
                      Opacity(
                        opacity: 0.6,
                        child: Text(
                          'User: ${userName ?? 'Unknown User'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Text('Public: ${playlist!.isPublic ? 'Yes' : 'No'}', style: const TextStyle(fontSize: 16)),
                      Text('Created At: ${playlist!.createdAt.toLocal()}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 24),
                      const Text('Songs:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      songs.isEmpty
                          ? const Center(child: Text('No songs in this playlist'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: songs.length,
                              itemBuilder: (context, index) {
                                final entry = songs[index];
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
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Confirm Remove'),
                                            content: Text('Are you sure you want to remove ${song.title} from this playlist?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  removeSongFromPlaylist(song.id);
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Remove'),
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
                    ],
                  ),
                ),
    );
  }
}