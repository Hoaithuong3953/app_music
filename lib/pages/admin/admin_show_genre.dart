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
        title: Text(
          genre != null ? genre!.title : 'Genre Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Songs',
            onPressed: addSongsToGenre,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Genre',
            onPressed: genre != null
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: Text('Are you sure you want to delete ${genre!.title}?'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              deleteGenre();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $errorMessage', style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                )
              : genre == null
                  ? const Center(child: Text('Failed to load genre'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  if (genre!.coverImage.isNotEmpty)
                                    Hero(
                                      tag: 'genre-${genre!.id}',
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          genre!.coverImage,
                                          width: 200,
                                          height: 200,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 200,
                                            height: 200,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 20),
                                  _buildInfoRow(Icons.title, 'Title', genre!.title),
                                  const SizedBox(height: 10),
                                  _buildInfoRow(Icons.description, 'Description', genre!.description),
                                  const SizedBox(height: 10),
                                  _buildInfoRow(
                                    Icons.calendar_today,
                                    'Created At',
                                    genre!.createdAt.toLocal().toString(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Artists', Icons.person),
                          const Divider(height: 1),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: artists.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(child: Text('No artists in this genre')),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: artists.length,
                                    itemBuilder: (context, index) {
                                      final artist = artists[index];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          child: Text(
                                            (artist['title'] ?? '?')[0].toUpperCase(),
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        title: Text(
                                          artist['title'] ?? 'Unknown Artist',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        trailing: const Icon(Icons.chevron_right),
                                        onTap: () {
                                          // Navigation logic here
                                        },
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Songs', Icons.music_note),
                          const Divider(height: 1),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: songs.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(child: Text('No songs in this genre')),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: songs.length,
                                    itemBuilder: (context, index) {
                                      final song = songs[index];
                                      return Dismissible(
                                        key: Key(song['id'] ?? ''),
                                        background: Container(
                                          color: Colors.red,
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(right: 20),
                                          child: const Icon(Icons.delete, color: Colors.white),
                                        ),
                                        direction: DismissDirection.endToStart,
                                        confirmDismiss: (direction) async {
                                          return await showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Confirm Remove'),
                                              content: Text(
                                                  'Are you sure you want to remove ${song['title']} from this genre?'),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(15),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                  child: const Text('Remove'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        onDismissed: (direction) {
                                          removeSongFromGenre(song['id'] ?? '');
                                        },
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
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}