import 'package:flutter/material.dart';
import '../../widgets/client/mini_player.dart';
import './home_page.dart';
import './chart_page.dart';
import './library_page.dart';
import './profile_page.dart';
import './playlist_detail_page.dart';
import './search_page.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Danh sách các route cho từng tab
  final List<String> _routes = [
    '/home',
    '/chart',
    '/library',
    '/profile',
  ];

  // Các route không hiển thị BottomNavigationBar và MiniPlayer
  final List<String> _fullScreenRoutes = [
    '/login',
    '/register',
    '/player-page',
    '/edit-profile',
    '/change-password',
    '/all-songs',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _navigatorKey.currentState?.pushReplacementNamed(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Navigator(
                key: _navigatorKey,
                initialRoute: '/home',
                onGenerateRoute: (settings) {
                  Widget page;
                  // Kiểm tra settings.name không null trước khi sử dụng
                  final routeName = settings.name;
                  if (routeName != null && _fullScreenRoutes.contains(routeName)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pushNamed(routeName, arguments: settings.arguments);
                    });
                    return null; // Trả về null để không xử lý trong Navigator con
                  }

                  switch (routeName) {
                    case '/home':
                      page = HomePage();
                      break;
                    case '/chart':
                      page = ChartPage();
                      break;
                    case '/library':
                      page = LibraryPage();
                      break;
                    case '/profile':
                      page = ProfilePage();
                      break;
                    case '/playlist-detail':
                      final arguments = settings.arguments as Map<String, dynamic>?;
                      final playlistId = arguments?['playlistId'] as String?;
                      page = PlaylistDetailPage(playlistId: playlistId);
                      break;
                    case '/search':
                      page = SearchPage();
                      break;
                    default:
                      page = HomePage();
                  }
                  return MaterialPageRoute(builder: (_) => page, settings: settings);
                },
              ),
            ),
            const MiniPlayer(),
            BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Charts'),
                BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Theme.of(context).primaryColor,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              showSelectedLabels: true,
              iconSize: 24,
              selectedFontSize: 12,
              onTap: _onItemTapped,
            ),
          ],
        ),
      ),
    );
  }
}