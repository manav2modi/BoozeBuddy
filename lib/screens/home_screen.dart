

// lib/screens/home_screen.dart
import 'package:flutter/cupertino.dart';
import '../models/drink.dart';
import '../services/storage_service.dart';
import '../widgets/drink_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State {
  final storage = StorageService();
  List drinks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    drinks = await storage.getDrinks();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('SipTrack 🍻'),
      ),
      child: SafeArea(
        child: drinks.isEmpty
            ? Center(child: Text('No drinks logged yet! 🍹'))
            : ListView.builder(
          itemCount: drinks.length,
          itemBuilder: (_, idx) => DrinkCard(drink: drinks[idx]),
        ),
      ),
    );
  }
}