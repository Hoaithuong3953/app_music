import 'package:app_music/service/album_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/album.dart';

class AlbumListScreen extends StatefulWidget {
  const AlbumListScreen({super.key});

  @override
  State<AlbumListScreen> createState() => _AlbumListScreenState();
}

class _AlbumListScreenState extends State<AlbumListScreen> {
  late Future<List<Album>> futureAlbums;

  @override
  void initState() {
    super.initState();
    futureAlbums = AlbumService().fetchAlbums();
  }

  // Hàm làm mới danh sách album
  Future<void> _refreshAlbums() async {
    setState(() {
      futureAlbums = AlbumService().fetchAlbums();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Album List'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAlbums,
        child: FutureBuilder<List<Album>>(
          future: futureAlbums,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No albums found'));
            }

            final albums = snapshot.data!;
            return ListView.builder(
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: album.coverImageURL != null
                        ? Image.network(
                      album.coverImageURL!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.album, size: 50);
                      },
                    )
                        : const Icon(Icons.album, size: 50),
                    title: Text(album.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Slug: ${album.slugify ?? 'Unknown'}'),
                        Text('Artist: ${album.artist?.title ?? 'Unknown'}'),
                        Text('Genre: ${album.genre?.title ?? 'Unknown'}'),
                        Text(
                          'Created: ${DateFormat('yyyy-MM-dd').format(album.createdAt)}',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}