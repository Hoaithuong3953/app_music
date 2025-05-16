import 'package:flutter/material.dart';
import '../../widgets/client/playlist_card.dart';
import '../../models/playlist.dart';

class LibraryPage extends StatefulWidget {
  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String? _selectedTab;

  final List<Map<String, dynamic>> playlists = [
    {
      'playlist': Playlist(
        id: '1',
        title: 'My Favorites',
        slugify: 'my-favorites',
        user: 'user_id_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      'ownerName': 'User',
      'songCount': 12,
    },
    {
      'playlist': Playlist(
        id: '2',
        title: 'Chill Vibes',
        slugify: 'chill-vibes',
        user: 'user_id_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      'ownerName': 'User',
      'songCount': 10,
    },
  ];

  void _selectTab(String tab) {
    setState(() {
      _selectedTab = (_selectedTab == tab) ? null : tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: EdgeInsets.fromLTRB(screenWidth * 0.04, screenHeight * 0.03, screenWidth * 0.04, 0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Library',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: screenHeight * 0.035,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.search,
                            size: screenHeight * 0.03,
                            color: Theme.of(context).highlightColor,
                          ),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add,
                            size: screenHeight * 0.03,
                            color: Theme.of(context).highlightColor,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                ...playlists.map(
                      (data) => PlaylistCard(
                    playlist: data['playlist'],
                    ownerName: data['ownerName'],
                    songCount: data['songCount'],
                  ),
                ).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}