import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_client.dart';
import '../../service/admin/admin_genre_service.dart';
import '../../service/client/song_service.dart';
import '../../models/genre.dart';
import '../../models/song.dart';
import '../../widgets/client/song_tile.dart';
import '../../providers/user_provider.dart';

class AdminShowGenrePage extends StatefulWidget {
  final String genreId;

  const AdminShowGenrePage({super.key, required this.genreId});

  @override
  _AdminShowGenrePageState createState() => _AdminShowGenrePageState();
}

class _AdminShowGenrePageState extends State<AdminShowGenrePage> {
  Genre? genre;
  List<Map<String, dynamic>> songs = [];
  bool isLoading = true;
  final AdminGenreService _genreService = AdminGenreService();
  final SongService _songService = SongService();
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    fetchGenreDetails();
  }

  Future<void> fetchGenreDetails() async {
    try {
      final fetchedGenre = await _genreService.getGenre(widget.genreId);
      List<Map<String, dynamic>> fetchedSongs = [];
      if (fetchedGenre.songs.isNotEmpty) {
        final validSongIds = fetchedGenre.songs.where((id) => id.isNotEmpty).toList();
        if (validSongIds.isNotEmpty) {
          final response = await _apiClient.get(
            'song/',
            queryParameters: {'_id': validSongIds.join(',')},
            token: Provider.of<UserProvider>(context, listen: false).user?.token,
          );
          if (response['success'] == true) {
            final songsData = response['data'] as List<dynamic>;
            fetchedSongs = songsData.map((json) {
              final song = Song.fromJson(json);
              return {
                'song': song,
                'artistName': json['artist']?['title']?.toString() ?? 'Unknown Artist',
              };
            }).toList();
          }
        }
      }
      setState(() {
        genre = fetchedGenre;
        songs = fetchedSongs;
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

  Future<void> deleteGenre() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _genreService.deleteGenre(
        genreId: widget.genreId,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Genre deleted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> addSongsToGenre() async {
    final allSongs = await _songService.getAllSongs();
    final selectedSongIds = <String>[];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Songs to Genre'),
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
                await _genreService.addSongsToGenre(
                  genreId: widget.genreId,
                  songIds: selectedSongIds,
                  token: userProvider.user?.token,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Songs added successfully')),
                );
                Navigator.pop(context);
                fetchGenreDetails();
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

  Future<void> removeSongFromGenre(String songId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final updatedSongIds = genre!.songs.where((id) => id != songId).toList();
      await _genreService.updateGenre(
        genreId: widget.genreId,
        songIds: updatedSongIds,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song removed successfully')),
      );
      fetchGenreDetails();
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
        title: Text(genre != null ? genre!.title : 'Genre Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addSongsToGenre,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: genre != null
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: Text('Are you sure you want to delete ${genre!.title}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              deleteGenre();
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
          : genre == null
              ? const Center(child: Text('Failed to load genre'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (genre!.coverImage != null)
                        Center(
                          child: Image.network(
                            genre!.coverImage,
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text('Title: ${genre!.title}', style: const TextStyle(fontSize: 16)),
                      Text('Description: ${genre!.description}', style: const TextStyle(fontSize: 16)),
                      Text('Created At: ${genre!.createdAt.toLocal()}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 24),
                      const Text('Songs:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      songs.isEmpty
                          ? const Center(child: Text('No songs in this genre'))
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
                                            content: Text('Are you sure you want to remove ${song.title} from this genre?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  removeSongFromGenre(song.id);
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