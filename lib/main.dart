// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_track/screens/onboarding_screen.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsApp.debugAllowBannerOverride = false;
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar color
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const SipTrackApp());
}

class SipTrackApp extends StatelessWidget {
  const SipTrackApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BoozeBuddy 🍻',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const OnboardingChecker(),
    );
  }
}

// Add this class to check if onboarding is needed
class OnboardingChecker extends StatefulWidget {
  const OnboardingChecker({Key? key}) : super(key: key);

  @override
  State<OnboardingChecker> createState() => _OnboardingCheckerState();
}

class _OnboardingCheckerState extends State<OnboardingChecker> {
  bool _initialized = false;
  bool _showOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    setState(() {
      _showOnboarding = !onboardingCompleted;
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    return _showOnboarding ? const OnboardingScreen() : const HomeScreen();
  }
}