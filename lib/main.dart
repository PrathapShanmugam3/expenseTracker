import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'expense_calculator/expense_app.dart';
import 'services/backup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Background Backup Service (only on mobile platforms)
  if (!kIsWeb) {
    await BackupService.initialize();
    await BackupService.scheduleDailyBackup();
  }
  
  runApp(const ExpenseCalculatorApp());
}
