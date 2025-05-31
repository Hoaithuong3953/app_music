import 'package:flutter/material.dart';
import 'package:music_player_app/providers/ranking_provider.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'pages/admin/dashboard_page.dart';
import 'routes/client_routes.dart';
import 'routes/admin_routes.dart';
import 'pages/client/main_page.dart';
import 'pages/client/login_page.dart';
import 'providers/user_provider.dart';
import 'providers/song_provider.dart';
import 'providers/playback_provider.dart';
import 'providers/audio_handler_provider.dart';

void main() {
  runApp(MusicPlayerApp());
}

class MusicPlayerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SongProvider()),
        ChangeNotifierProvider(create: (_) => PlaybackProvider()),
        ChangeNotifierProxyProvider2<PlaybackProvider, SongProvider, AudioHandlerProvider>(
          create: (context) => AudioHandlerProvider(
            Provider.of<PlaybackProvider>(context, listen: false),
            Provider.of<SongProvider>(context, listen: false),
          ),
          update: (context, playbackProvider, songProvider, audioHandlerProvider) {
            audioHandlerProvider!.update(playbackProvider);
            return audioHandlerProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => RankingProvider()),
      ],
      child: MaterialApp(
        title: 'Music Player',
        theme: buildAppTheme(),
        debugShowCheckedModeBanner: false,
        home: AppInitializer(),
        routes: {
          ...clientRoutes,
          ...adminRoutes,
          '/main': (context) => MainPage(),
          '/login': (context) => LoginPage(),
          '/admin/dashboard': (context) => DashboardPage(),
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late Future<void> _loadUserFuture;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _loadUserFuture = userProvider.loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadUserFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          print('Error loading user: ${snapshot.error}');
          return LoginPage();
        }

        final userProvider = Provider.of<UserProvider>(context);
        final user = userProvider.user;
        if (user == null) {
          return LoginPage();
        }

        print('User role after initialization: ${user.role}');
        if (user.role == 'admin') {
          print('Navigating to DashboardPage for admin');
          return DashboardPage();
        } else {
          print('Navigating to MainPage for user');
          return MainPage();
        }
      },
    );
  }
}