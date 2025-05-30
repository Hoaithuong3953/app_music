import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  List<Map<String, dynamic>> artists = [];
  bool isLoading = true;
  String? errorMessage;
  final AdminGenreService _genreService = AdminGenreService();
  final SongService _songService = SongService();

  @override
  void initState() {
    super.initState();
    fetchGenreDetails();
  }

  Future<void> fetchGenreDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = userProvider.user?.token ?? '';
      print('Fetching genre with ID: ${widget.genreId}, Token: $token'); // Debug
      final data = await _genreService.getGenreDetails(
        widget.genreId,
        token: token,
      );
      final fetchedArtists = await _genreService.getArtistsInGenre(
        genreId: widget.genreId,
        token: token,
      );
      setState(() {
        genre = data['genre'];
        songs = data['songs'];
        artists = fetchedArtists;
        isLoading = false;
        print('Fetched genre: ${genre?.title}, Songs: ${songs.length}, Artists: ${artists.length}'); // Debug
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        print('Error fetching genre: $e'); // Debug
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
      await _genreService.removeSongFromGenre(
        genreId: widget.genreId,
        songId: songId,
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
          : errorMessage != null
              ? Center(child: Text('Error: $errorMessage'))
              : genre == null
                  ? const Center(child: Text('Failed to load genre'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (genre!.coverImage.isNotEmpty)
                            Center(
                              child: Image.network(
                                genre!.coverImage,
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.image_not_supported,
                                  size: 150,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text('Title: ${genre!.title}', style: const TextStyle(fontSize: 16)),
                          Text('Description: ${genre!.description}',
                              style: const TextStyle(fontSize: 16)),
                          Text('Created At: ${genre!.createdAt.toLocal()}',
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 24),
                          const Text('Artists:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(),
                          artists.isEmpty
                              ? const Center(child: Text('No artists in this genre'))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: artists.length,
                                  itemBuilder: (context, index) {
                                    final artist = artists[index];
                                    return ListTile(
                                      title: Text(artist['title'] ?? 'Unknown Artist'),
                                      onTap: () {
                                        // Điều hướng đến trang chi tiết nghệ sĩ nếu cần
                                      },
                                    );
                                  },
                                ),
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
                                    final song = songs[index];
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: SongTile(
                                            song: Song(
                                              id: song['id'] ?? '',
                                              title: song['title'] ?? '',
                                              description: '',
                                              lyrics: '',
                                              artist: song['artistName'] ?? 'Unknown Artist',
                                              album: '',
                                              genre: [],
                                              duration: '',
                                              slugify: '',
                                              url: '',
                                              coverImage: '',
                                              views: 0,
                                              dailyViews: 0,
                                              weeklyViews: 0,
                                              trendingScore: 0,
                                              lastReset: DateTime.now(),
                                              likes: [],
                                              dislikes: [],
                                              comments: [],
                                              isPublic: true,
                                              createdAt: DateTime.now(),
                                              updatedAt: DateTime.now(),
                                            ),
                                            artistName: song['artistName'] ?? 'Unknown Artist',
                                            index: index + 1,
                                            onTap: () => Navigator.pushNamed(
                                              context,
                                              '/admin/song/:sid',
                                              arguments: song['id'],
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
                                                content: Text(
                                                    'Are you sure you want to remove ${song['title']} from this genre?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      removeSongFromGenre(song['id'] ?? '');
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