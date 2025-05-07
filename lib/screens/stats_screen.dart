// lib/screens/stats_screen.dart
import 'package:flutter/cupertino.dart';
import '../models/drink.dart';
import '../services/storage_service.dart';

class StatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State {
  final storage = StorageService();
  List allDrinks = [];
  int segment = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    allDrinks = await storage.getDrinks();
    setState(() {});
  }

  List get filtered {
    final now = DateTime.now();
    if (segment == 0) {
// Today
      return allDrinks
          .where((d) =>
      d.dateTime.year == now.year &&
          d.dateTime.month == now.month &&
          d.dateTime.day == now.day)
          .toList();
    } else if (segment == 1) {
// Last 7 days
      return allDrinks
          .where((d) => d.dateTime
          .isAfter(now.subtract(Duration(days: 7))))
          .toList();
    } else {
// Last 30 days
      return allDrinks
          .where((d) => d.dateTime
          .isAfter(now.subtract(Duration(days: 30))))
          .toList();
    }
  }

  double get totalSpent =>
      filtered.fold(0.0, (sum, d) => sum + (d.cost ?? 0));

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Your Stats 📊'),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CupertinoSegmentedControl(
                children: {
                  0: Text('Today'),
                  1: Text('7 days'),
                  2: Text('30 days'),
                },
                groupValue: segment,
                onValueChanged: (int v) => setState(() => segment = v),
              ),
              SizedBox(height: 20),
              Text('Drinks: ${filtered.length}',
                  style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text('Spent: ${totalSpent.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}