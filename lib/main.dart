import 'package:app_music/providers/artist_provider.dart';
import 'package:app_music/providers/home_provider.dart';
import 'package:app_music/providers/search_provider.dart';
import 'package:app_music/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/library_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/music_player.dart';
import 'providers/audio_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ArtistProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  final UserService userService = UserService(baseUrl: 'http://10.0.2.2:8080');

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      setState(() {
        _isLoggedIn = false;
      });
      return;
    }

    // Có token, thử lấy thông tin người dùng từ API
    try {
      final user = await userService.getCurrentUser();
      if (user != null) {
        setState(() {
          _isLoggedIn = true;
        });
      } else {
        // Token không hợp lệ, xóa token và user_data
        await prefs.remove('accessToken');
        await prefs.remove('user_data');
        setState(() {
          _isLoggedIn = false;
        });
      }
    } catch (e) {
      debugPrint("Error checking login status: $e");
      // Nếu API thất bại, thử dùng dữ liệu từ SharedPreferences
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        setState(() {
          _isLoggedIn = true;
        });
      } else {
        // Không có dữ liệu user, xóa token và chuyển hướng đến LoginScreen
        await prefs.remove('accessToken');
        setState(() {
          _isLoggedIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music App',
      theme: ThemeData(
        primaryColor: const Color(0xFFA6B9FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFA6B9FF),
        ),
      ),
      home: _isLoggedIn ? const MainScreen() : const LoginScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Nội dung chính của màn hình (có thể cuộn)
          Expanded(
            child: _screens[_selectedIndex],
          ),
          // MusicPlayer và BottomNavigationBar ở dưới cùng
          const MusicPlayer(),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFA6B9FF), Color(0xFF8A9EFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 12,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.home, size: _selectedIndex == 0 ? 30 : 24),
                  ),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.search, size: _selectedIndex == 1 ? 30 : 24),
                  ),
                  label: "Search",
                ),
                BottomNavigationBarItem(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.library_music, size: _selectedIndex == 2 ? 30 : 24),
                  ),
                  label: "Library",
                ),
                BottomNavigationBarItem(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.person, size: _selectedIndex == 3 ? 30 : 24),
                  ),
                  label: "Profile",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}