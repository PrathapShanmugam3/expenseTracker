import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../expense_calculator/utils/app_config.dart';

const String backupTask = "backupTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == backupTask) {
      return await BackupService.performBackup();
    }
    return Future.value(true);
  });
}

class BackupService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Set to true to see notifications for testing
    );
  }

  static Future<void> scheduleDailyBackup() async {
    // Calculate initial delay to 10 PM
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 22, 0);
    
    // If 10 PM has passed, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    
    final initialDelay = scheduledTime.difference(now);
    print("Scheduling backup in ${initialDelay.inHours} hours and ${initialDelay.inMinutes % 60} minutes");

    await Workmanager().registerPeriodicTask(
      "daily_backup_10pm",
      backupTask,
      frequency: const Duration(hours: 24),
      initialDelay: initialDelay,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }

  static String? lastError;

  static Future<bool> performBackup() async {
    lastError = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdInt = prefs.getInt(AppConfig.userIdKey);
      final userId = userIdInt?.toString();
      
      if (userId == null) {
        lastError = "No user logged in";
        print("Backup skipped: No user logged in");
        return false;
      }

      print("Starting backup for user: $userId");
      try {
        final response = await http.get(
          Uri.parse('${AppConfig.baseUrl}/admin/backup'),
          headers: {'x-user-id': userId},
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final dir = await getApplicationDocumentsDirectory();
          final backupDir = Directory('${dir.path}/backups');
          if (!await backupDir.exists()) {
            await backupDir.create(recursive: true);
          }

          final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
          final filename = "backup_$timestamp.sql";
          final file = File('${backupDir.path}/$filename');
          await file.writeAsString(response.body);
          
          print("Backup successful: ${file.path}");
          
          await _cleanupOldBackups(backupDir);
          return true;
        } else {
          lastError = "Server error: ${response.statusCode}";
          if (response.statusCode == 403) lastError = "Access Denied: Admin only";
          print("Backup failed: ${response.statusCode} - ${response.body}");
          return false;
        }
      } catch (e) {
        lastError = "Connection failed: $e";
        print("Backup connection error: $e");
        return false;
      }
    } catch (e) {
      lastError = "Error: $e";
      print("Backup error: $e");
      return false;
    }
  }

  static Future<void> _cleanupOldBackups(Directory backupDir) async {
    try {
      final files = backupDir.listSync()
          .where((e) => e is File && e.path.endsWith('.sql'))
          .toList();
      
      // Sort by modification time (newest first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      // Keep last 7
      if (files.length > 7) {
        for (var i = 7; i < files.length; i++) {
          await files[i].delete();
          print("Deleted old backup: ${files[i].path}");
        }
      }
    } catch (e) {
      print("Cleanup error: $e");
    }
  }
  
  // Method to restore from a file
  static Future<bool> restoreBackup(File file) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdInt = prefs.getInt(AppConfig.userIdKey);
      final userId = userIdInt?.toString();
      
      if (userId == null) return false;

      final content = await file.readAsString();
      
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/admin/restore'),
        headers: {
          'x-user-id': userId,
          'Content-Type': 'text/plain',
        },
        body: content,
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Restore error: $e");
      return false;
    }
  }
}
