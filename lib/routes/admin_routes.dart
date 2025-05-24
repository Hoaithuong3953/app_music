import 'package:flutter/material.dart';
import '../pages/admin/dashboard_page.dart';
import '../pages/admin/admin_user.dart';
import '../pages/admin/admin_song.dart';
import '../pages/admin/admin_show_user.dart';
import '../pages/admin/admin_show_song.dart';
import '../pages/admin/admin_playlist.dart';
import '../pages/admin/admin_show_playlist.dart';
import '../pages/admin/admin_genre.dart';
import '../pages/admin/admin_show_genre.dart';
import '../pages/admin/admin_album.dart';
import '../pages/admin/admin_show_album.dart';

final adminRoutes = {
  '/admin/dashboard': (context) => const DashboardPage(),
  '/admin/users': (context) => const AdminUserPage(),
  '/admin/songs': (context) => const AdminSongPage(),
  '/admin/playlists': (context) => const AdminPlaylistPage(),
  '/admin/genres': (context) => const AdminGenrePage(),
  '/admin/albums': (context) => const AdminAlbumPage(),
  '/admin/user/:uid': (context) {
    final userId = ModalRoute.of(context)!.settings.arguments as String;
    return AdminShowUserPage(userId: userId);
  },
  '/admin/song/:sid': (context) {
    final songId = ModalRoute.of(context)!.settings.arguments as String;
    return AdminShowSongPage(songId: songId);
  },
  '/admin/playlist/:pid': (context) {
    final playlistId = ModalRoute.of(context)!.settings.arguments as String;
    return AdminShowPlaylistPage(playlistId: playlistId);
  },
  '/admin/genre/:gid': (context) {
    final genreId = ModalRoute.of(context)!.settings.arguments as String;
    return AdminShowGenrePage(genreId: genreId);
  },
  '/admin/album/:aid': (context) {
    final albumId = ModalRoute.of(context)!.settings.arguments as String;
    return AdminShowAlbumPage(albumId: albumId);
  },
};