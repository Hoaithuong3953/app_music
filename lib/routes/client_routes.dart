import 'package:flutter/material.dart';
import '../pages/client/home_page.dart';
import '../pages/client/login_page.dart';
import '../pages/client/register_page.dart';
import '../pages/client/chart_page.dart';
import '../pages/client/library_page.dart';
import '../pages/client/player_page.dart';
import '../pages/client/main_page.dart';
import '../pages/client/profile_page.dart';
import '../pages/client/edit_profile_page.dart';
import '../pages/client/change_password_page.dart';
import '../pages/client/all_songs_page.dart';
import '../pages/client/playlist_detail_page.dart';
import '../pages/client/search_page.dart';

final clientRoutes = {
  '/login': (context) => LoginPage(),
  '/register': (context) => RegisterPage(),
  '/main': (context) => MainPage(),
  '/home': (context) => HomePage(),
  '/chart': (context) => ChartPage(),
  '/library': (context) => LibraryPage(),
  '/profile': (context) => ProfilePage(),
  '/playlist-detail': (context) {
    final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final playlistId = arguments?['playlistId'] as String?;
    return PlaylistDetailPage(playlistId: playlistId);
  },
  '/player-page': (context) => PlayerPage(),
  '/edit-profile': (context) => EditProfilePage(),
  '/change-password': (context) => ChangePasswordPage(),
  '/all-songs': (context) => AllSongsPage(),
  '/search': (context) => SearchPage(),
};