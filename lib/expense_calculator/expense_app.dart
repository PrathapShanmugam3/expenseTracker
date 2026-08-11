import 'package:flutter/material.dart';
import 'screens/expense_splash_screen.dart';
import 'utils/app_theme.dart';
import 'utils/theme_provider.dart';

import '../notification_service.dart';

/// Main entry point for Expense Calculator App with Theme Support
class ExpenseCalculatorApp extends StatefulWidget {
  const ExpenseCalculatorApp({super.key});

  // Static method to access theme provider from anywhere
  static _ExpenseCalculatorAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_ExpenseCalculatorAppState>();
  }

  @override
  State<ExpenseCalculatorApp> createState() => _ExpenseCalculatorAppState();
}

class _ExpenseCalculatorAppState extends State<ExpenseCalculatorApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  ThemeProvider get themeProvider => _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(_onThemeChanged);
    _initServices();
  }

  Future<void> _initServices() async {
    await NotificationService().init();
    // Cancel all old scheduled notifications (e.g. "Time to call")
    await NotificationService().cancelAllNotifications();
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void toggleTheme() {
    _themeProvider.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Expense Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const ExpenseSplashScreen(),
    );
  }
}
