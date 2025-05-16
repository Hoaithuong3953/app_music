import 'package:flutter/material.dart';

class GenreCard extends StatelessWidget {
  final String genre;

  const GenreCard({required this.genre, super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final cardSize = screenWidth * 0.25;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      child: Container(
        width: cardSize,
        height: cardSize,
        alignment: Alignment.center,
        padding: EdgeInsets.all(screenWidth * 0.02),
        child: Text(
          genre,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: screenHeight * 0.02,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}