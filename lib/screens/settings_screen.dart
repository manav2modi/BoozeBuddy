// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/settings_service.dart';
import 'citations_screen.dart';
import 'custom_drinks_screen.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();

  bool _costTrackingEnabled = false;
  String _currencySymbol = '\$';
  bool _isLoading = true;

  // Available currency symbols
  final List<String> _availableCurrencies = [
    '\$', // USD
    '€', // EUR
    '£', // GBP
    '¥', // JPY/CNY
    '₹', // INR
    'A\$', // AUD
    'C\$', // CAD
    '₽', // RUB
    '₩', // KRW
    '₺', // TRY
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final costTrackingEnabled = await _settingsService.getCostTrackingEnabled();
      final currencySymbol = await _settingsService.getCurrencySymbol();

      setState(() {
        _costTrackingEnabled = costTrackingEnabled;
        _currencySymbol = currencySymbol;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCostTrackingEnabled(bool value) async {
    setState(() {
      _costTrackingEnabled = value;
    });

    await _settingsService.setCostTrackingEnabled(value);
  }

  Future<void> _updateCurrencySymbol(String value) async {
    setState(() {
      _currencySymbol = value;
    });

    await _settingsService.setCurrencySymbol(value);
  }

  void _showCurrencyPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: const Color(0xFF2C2C2C),
          child: Column(
            children: [
              Container(
                height: 44,
                color: const Color(0xFF2C2C2C),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 0, color: Color(0xFF3D3D3D)),
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: const Color(0xFF2C2C2C),
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: _availableCurrencies.indexOf(_currencySymbol),
                  ),
                  onSelectedItemChanged: (int index) {
                    _updateCurrencySymbol(_availableCurrencies[index]);
                  },
                  children: _availableCurrencies.map((symbol) {
                    return Center(
                      child: Text(
                        symbol,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF121212),
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFF222222),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF333333),
            width: 0.5,
          ),
        ),
        middle: Text('Settings'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
          children: [
            const SizedBox(height: 16),

            // Cost Tracking Section
            _buildSectionHeader('Cost Tracking'),
            _buildSettingItem(
              title: 'Track Costs',
              subtitle: 'Enable cost tracking for drinks',
              trailing: CupertinoSwitch(
                value: _costTrackingEnabled,
                activeColor: CupertinoColors.activeBlue,
                onChanged: _updateCostTrackingEnabled,
              ),
            ),

            // Only show currency options if cost tracking is enabled
            if (_costTrackingEnabled)
              _buildSettingItem(
                title: 'Currency',
                subtitle: 'Select your preferred currency',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currencySymbol,
                      style: const TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      CupertinoIcons.chevron_right,
                      color: Color(0xFF888888),
                      size: 20,
                    ),
                  ],
                ),
                onTap: _showCurrencyPicker,
              ),

            // _buildSectionHeader('Notifications'),
            // _buildSettingItem(
            //   title: 'Notification Settings',
            //   subtitle: 'Manage reminders and alerts',
            //   trailing: const Icon(
            //     CupertinoIcons.chevron_right,
            //     color: Color(0xFF888888),
            //     size: 20,
            //   ),
            //   onTap: () {
            //     Navigator.of(context).push(
            //       CupertinoPageRoute(
            //         builder: (context) => const NotificationSettingsScreen(),
            //       ),
            //     );
            //   },
            // ),

            _buildSectionHeader('Health Information'),
            _buildSettingItem(
              title: 'Citation Sources',
              subtitle: 'View medical citations and health information sources',
              trailing: const Icon(
                CupertinoIcons.chevron_right,
                color: Color(0xFF888888),
                size: 20,
              ),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => const CitationsScreen(),
                  ),
                );
              },
            ),

            _buildSectionHeader('Customization'),
            _buildSettingItem(
              title: 'Custom Drinks',
              subtitle: 'Create and manage your own drink types',
              trailing: const Icon(
                CupertinoIcons.chevron_right,
                color: Color(0xFF888888),
                size: 20,
              ),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => const CustomDrinksScreen(),
                  ),
                );
              },
            ),

            // About Section
            _buildSectionHeader('About'),
            _buildSettingItem(
              title: 'Version',
              subtitle: 'BoozeBuddy 1.0.0',
            ),
            _buildSettingItem(
              title: 'Made with',
              subtitle: 'Flutter & ❤️',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: CupertinoColors.activeBlue,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: const Color(0xFF222222),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 14,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}