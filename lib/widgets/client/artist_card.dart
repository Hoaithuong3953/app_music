import 'package:flutter/material.dart';
import '../../models/artist.dart';

class ArtistCard extends StatelessWidget {
  final Artist artist;

  const ArtistCard({required this.artist, super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final avatarRadius = screenHeight * 0.06;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Theme.of(context).primaryColor,
            backgroundImage: artist.avatar != null ? NetworkImage(artist.avatar!) : null,
            child: artist.avatar == null
                ? Text(
              artist.title.isNotEmpty ? artist.title[0].toUpperCase() : 'A',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: avatarRadius * 0.8,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
                : null,
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            artist.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: screenHeight * 0.02,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}