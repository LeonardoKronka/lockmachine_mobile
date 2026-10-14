import 'package:flutter/material.dart';

import 'models/lockmachine_alert.dart';
import 'screens/alert_detail_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LockMachineApp());
}

class LockMachineApp extends StatefulWidget {
  const LockMachineApp({super.key, this.service, this.initialize = true});
  final NotificationService? service;
  final bool initialize;

  @override
  State<LockMachineApp> createState() => _LockMachineAppState();
}

class _LockMachineAppState extends State<LockMachineApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final NotificationService _service;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? NotificationService();
    _service.onOpenAlert = _openAlert;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.initialize) _service.initialize();
    });
  }

  void _openAlert(LockMachineAlert alert) {
    if (!mounted) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openAlert(alert));
      return;
    }
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => AlertDetailScreen(alert: alert)),
      (route) => route.isFirst,
    );
  }

  @override
  void dispose() {
    _service.onOpenAlert = null;
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigatorKey,
    title: 'LockMachine Mobile',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF101114),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE53935),
        brightness: Brightness.dark,
        primary: const Color(0xFFFF5550),
        surface: const Color(0xFF1B1D22),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF101114),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF303239)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
    home: HomeScreen(service: _service),
  );
}
