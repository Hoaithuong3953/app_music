import 'package:flutter/material.dart';

import '../models/song.dart';

class SearchResults extends StatelessWidget {
  final List<Song> filteredSongs;

  const SearchResults({super.key, required this.filteredSongs});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: filteredSongs.isEmpty
          ? const Center(child: Text("No songs found"))
          : ListView.builder(
        itemCount: filteredSongs.length,
        itemBuilder: (context, index) {
          final song = filteredSongs[index];
          return ListTile(
            leading: Image.network(song.coverImage ?? 'default_image_url', width: 50, height: 50, fit: BoxFit.cover),
            title: Text(song.title),
            subtitle: Text(song.artist?.title ?? 'Unknown Artist'),
            onTap: () {},
          );
        },
      ),
    );
  }
}
