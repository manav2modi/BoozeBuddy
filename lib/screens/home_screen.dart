// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/drink.dart';
import '../services/storage_service.dart';
import 'add_drink_screen.dart';
import 'stats_screen.dart';
import '../widgets/drink_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final StorageService _storageService = StorageService();
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  List<Drink> _drinks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDrinks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDrinks() async {
    setState(() {
      _isLoading = true;
    });

    final drinks = await _storageService.getDrinksForDate(_selectedDate);

    setState(() {
      _drinks = drinks;
      _isLoading = false;
    });
  }

  double get _totalStandardDrinks {
    return _drinks.fold(0, (sum, drink) => sum + drink.standardDrinks);
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.amber,
              onPrimary: Colors.black,
              surface: Color(0xFF2C2C2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDrinks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              floating: true,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'SipTrack 🍻',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 3.0,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _selectDate(context),
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                DateFormat('MMM d, yyyy').format(_selectedDate),
                                style: const TextStyle(fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "${_totalStandardDrinks.toStringAsFixed(1)} 🥃",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: "Today's Drinks"),
                  Tab(text: "Stats"),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Today's Drinks Tab
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _drinks.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_bar_outlined,
                    size: 72,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No drinks logged for ${DateFormat('MMM d').format(_selectedDate)}",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AddDrinkScreen(),
                        ),
                      );

                      if (result == true) {
                        _loadDrinks();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Add Your First Drink"),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadDrinks,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _drinks.length,
                itemBuilder: (context, index) {
                  final drink = _drinks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DrinkCard(
                      drink: drink,
                      onDelete: () async {
                        await _storageService.deleteDrink(drink.id);
                        _loadDrinks();
                      },
                    ),
                  );
                },
              ),
            ),

            // Stats Tab
            const StatsScreen(),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddDrinkScreen(),
            ),
          );

          if (result == true) {
            _loadDrinks();
          }
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}