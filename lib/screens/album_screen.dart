import 'package:app_music/service/album_service.dart';
import 'package:flutter/material.dart';
import '../models/album.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late Future<List<Album>> futureAlbums;

  @override
  void initState() {
    super.initState();
    futureAlbums = AlbumService().fetchAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Album List'),
      ),
      body: FutureBuilder<List<Album>>(
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
                  leading: album.coverImageUrl != null
                      ? Image.network(
                    album.coverImageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                      : const Icon(Icons.album, size: 50),
                  title: Text(album.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Slug: ${album.slugify}'),
                      Text('Created: ${album.createdAt.toLocal().toString().split(' ')[0]}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}