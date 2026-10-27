import 'dart:async';

import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'screens/check_screen.dart';
import 'screens/history_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'services/local_store.dart';

const Color satarkNavy = Color(0xFF171B3B);
const Color satarkTeal = Color(0xFF13877D);
const Color satarkAmber = Color(0xFFF6B93B);
const Color satarkPaper = Color(0xFFF7F6F0);
const Color satarkInk = Color(0xFF202744);

class SatarkApp extends StatelessWidget {
  const SatarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: satarkPaper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: satarkTeal,
        primary: satarkTeal,
        secondary: satarkAmber,
        surface: Colors.white,
        error: const Color(0xFFB3261E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: satarkNavy,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFE8E8E2)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD8DAD6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD8DAD6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: satarkTeal, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: satarkTeal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: satarkNavy, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(color: satarkNavy, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(color: satarkInk, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: satarkInk, fontSize: 16, height: 1.45),
        bodyMedium: TextStyle(color: satarkInk, fontSize: 14, height: 1.4),
      ),
    );

    return MaterialApp(
      title: 'Satark',
      debugShowCheckedModeBanner: false,
      theme: base,
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  String _language = 'English';
  bool _onboardingComplete = false;
  bool _startupLoading = true;
  List<SharedMediaFile> _pendingShares = [];
  final GlobalKey<CheckScreenState> _checkScreenKey = GlobalKey<CheckScreenState>();
  StreamSubscription<List<SharedMediaFile>>? _shareSubscription;

  @override
  void initState() {
    super.initState();
    _loadStartupSettings();
    _listenForSharedContent();
  }

  Future<void> _listenForSharedContent() async {
    _shareSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleSharedContent,
      onError: (_) {},
    );
    try {
      final initialItems = await ReceiveSharingIntent.instance.getInitialMedia();
      if (initialItems.isNotEmpty) _handleSharedContent(initialItems);
    } catch (_) {
      // A share source may occasionally return no usable initial payload.
    }
  }

  void _handleSharedContent(List<SharedMediaFile> items) {
    if (!mounted || items.isEmpty) return;
    if (!_onboardingComplete) {
      _pendingShares = items;
      return;
    }
    setState(() => _selectedIndex = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final checkScreen = _checkScreenKey.currentState;
      if (checkScreen != null) unawaited(checkScreen.handleSharedMedia(items));
      unawaited(ReceiveSharingIntent.instance.reset());
    });
  }

  Future<void> _loadStartupSettings() async {
    final values = await Future.wait([LocalStore.getLanguage(), LocalStore.isOnboardingComplete()]);
    if (mounted) {
      final completed = values[1] as bool;
      setState(() {
        _language = values[0] as String;
        _onboardingComplete = completed;
        _startupLoading = false;
      });
      if (completed && _pendingShares.isNotEmpty) {
        final pending = _pendingShares;
        _pendingShares = [];
        _handleSharedContent(pending);
      }
    }
  }

  Future<void> _completeOnboarding(String language, String contactName, String contactPhone, bool historyEnabled) async {
    await LocalStore.setLanguage(language);
    await LocalStore.saveContact(name: contactName, phone: contactPhone);
    await LocalStore.setHistoryEnabled(historyEnabled);
    await LocalStore.markOnboardingComplete();
    if (!mounted) return;
    setState(() {
      _language = language;
      _onboardingComplete = true;
    });
    if (_pendingShares.isNotEmpty) {
      final pending = _pendingShares;
      _pendingShares = [];
      _handleSharedContent(pending);
    }
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setLanguage(String language) async {
    setState(() => _language = language);
    await LocalStore.setLanguage(language);
  }

  @override
  Widget build(BuildContext context) {
    if (_startupLoading) {
      return const Scaffold(backgroundColor: satarkNavy, body: Center(child: CircularProgressIndicator(color: satarkAmber)));
    }
    if (!_onboardingComplete) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }
    final pages = <Widget>[
      CheckScreen(key: _checkScreenKey, language: _language, onLanguageChanged: _setLanguage),
      const HistoryScreen(),
      SettingsScreen(language: _language, onLanguageChanged: _setLanguage),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        height: 74,
        selectedIndex: _selectedIndex,
        backgroundColor: Colors.white,
        indicatorColor: satarkTeal.withValues(alpha: 0.14),
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Check'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
        ],
      ),
    );
  }
}
