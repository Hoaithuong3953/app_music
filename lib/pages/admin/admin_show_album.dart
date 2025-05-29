import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_client.dart';
import '../../service/admin/admin_album_service.dart';
import '../../service/client/song_service.dart';
import '../../service/admin/admin_genre_service.dart';
import '../../models/album.dart';
import '../../models/song.dart';
import '../../models/genre.dart';
import '../../widgets/client/song_tile.dart';
import '../../providers/user_provider.dart';

class AdminShowAlbumPage extends StatefulWidget {
  final String albumId;

  const AdminShowAlbumPage({super.key, required this.albumId});

  @override
  _AdminShowAlbumPageState createState() => _AdminShowAlbumPageState();
}

class _AdminShowAlbumPageState extends State<AdminShowAlbumPage> {
  Map<String, dynamic>? albumData;
  List<Map<String, dynamic>> songs = [];
  bool isLoading = true;
  final AdminAlbumService _albumService = AdminAlbumService();
  final SongService _songService = SongService();
  final AdminGenreService _genreService = AdminGenreService();
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    fetchAlbumDetails();
  }

  Future<void> fetchAlbumDetails() async {
    try {
      final fetchedAlbumData = await _albumService.getAlbumById(widget.albumId);
      List<Map<String, dynamic>> fetchedSongs = [];
      if (fetchedAlbumData['album'].songs.isNotEmpty) {
        final validSongIds = fetchedAlbumData['album'].songs.where((id) => id.isNotEmpty && id != fetchedAlbumData['album'].id).toList();
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
        albumData = fetchedAlbumData;
        songs = fetchedSongs;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        albumData = null;
        songs = [];
        isLoading = false;
      });
    }
  }

  Future<void> deleteAlbum() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _albumService.deleteAlbum(
        albumId: widget.albumId,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album deleted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> addSongsToAlbum() async {
    final allSongs = await _songService.getAllSongs();
    final selectedSongIds = <String>[];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Songs to Album'),
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
                await _albumService.addSongsToAlbum(
                  albumId: widget.albumId,
                  songIds: selectedSongIds,
                  token: userProvider.user?.token,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Songs added successfully')),
                );
                Navigator.pop(context);
                fetchAlbumDetails();
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

  Future<void> removeSongFromAlbum(String songId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final updatedSongIds = albumData!['album'].songs.where((id) => id != songId).toList();
      await _albumService.updateAlbum(
        albumId: widget.albumId,
        songIds: updatedSongIds,
        token: userProvider.user?.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song removed successfully')),
      );
      fetchAlbumDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> addGenreToAlbum() async {
    final allGenres = await _genreService.getAllGenres();
    String? selectedGenreId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Genre to Album'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: allGenres.map((entry) {
                final genre = entry['genre'] as Genre;
                return RadioListTile<String>(
                  title: Text(genre.title),
                  value: genre.id,
                  groupValue: selectedGenreId,
                  onChanged: (value) {
                    setState(() {
                      selectedGenreId = value;
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
              if (selectedGenreId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a genre')),
                );
                return;
              }
              try {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await _albumService.addGenreToAlbum(
                  albumId: widget.albumId,
                  genreId: selectedGenreId!,
                  token: userProvider.user?.token,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Genre added successfully')),
                );
                Navigator.pop(context);
                fetchAlbumDetails();
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(albumData != null ? albumData!['album'].title : 'Album Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addSongsToAlbum,
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: addGenreToAlbum,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: albumData != null
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: Text('Are you sure you want to delete ${albumData!['album'].title}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              deleteAlbum();
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
          : albumData == null
              ? const Center(child: Text('Failed to load album'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (albumData!['album'].coverImageURL != null)
                        Center(
                          child: Image.network(
                            albumData!['album'].coverImageURL,
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 150),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text('Title: ${albumData!['album'].title}', style: const TextStyle(fontSize: 16)),
                      Text('Artist: ${albumData!['artistName'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                      Text('Genre: ${albumData!['album'].genre ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                      Text('Created At: ${albumData!['album'].createdAt.toLocal()}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 24),
                      const Text('Songs:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      songs.isEmpty
                          ? const Center(child: Text('No songs in this album'))
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
                                            content: Text('Are you sure you want to remove ${song.title} from this album?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  removeSongFromAlbum(song.id);
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