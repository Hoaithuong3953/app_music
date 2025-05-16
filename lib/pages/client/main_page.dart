import 'package:flutter/material.dart';
import '../../widgets/client/mini_player.dart';
import './home_page.dart';
import './chart_page.dart';
import './library_page.dart';
import './profile_page.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // Danh sách các trang con
  final List<Widget> _pages = [
    HomePage(),
    ChartPage(),
    LibraryPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
              child: _pages[_selectedIndex],
            ),
            MiniPlayer(),
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