// lib/main.dart
import 'package:flutter/cupertino.dart';
import 'screens/home_screen.dart';
import 'screens/add_drink_screen.dart';
import 'screens/stats_screen.dart';

void main() {
  runApp(SipTrackApp());
}

class SipTrackApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'SipTrack 🍻',
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.systemTeal,
      ),
      home: AppHome(),
    );
  }
}

class AppHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.list_bullet),
            label: 'Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.add_circled),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar),
            label: 'Stats',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(builder: (_) => HomeScreen());
          case 1:
            return CupertinoTabView(builder: (_) => AddDrinkScreen());
          case 2:
            return CupertinoTabView(builder: (_) => StatsScreen());
          default:
            return CupertinoTabView(builder: (_) => HomeScreen());
        }
      },
    );
  }
}
