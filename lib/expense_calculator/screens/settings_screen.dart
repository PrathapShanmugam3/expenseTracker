import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../expense_app.dart';
import 'admin_panel_screen.dart';
import 'backup_restore_screen.dart';

/// Settings Screen - Theme toggle and app settings
class SettingsScreen extends StatefulWidget {
  final int userId;
  
  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAdmin = prefs.getInt('userRoleId') == 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 30),
            
            // Admin Section (only if admin)
            if (_isAdmin) ...[
              Text('Admin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    ListTile(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminPanelScreen(userId: widget.userId)));
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryColor),
                      ),
                      title: Text('Admin Panel', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                      subtitle: Text('Manage categories & users', style: TextStyle(color: textSecondary, fontSize: 12)),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: textSecondary, size: 16),
                    ),
                    Divider(height: 1, color: textSecondary.withOpacity(0.1)),
                    ListTile(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const BackupRestoreScreen()));
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.backup_rounded, color: Colors.blue),
                      ),
                      title: Text('Backup & Restore', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                      subtitle: Text('Manage database backups', style: TextStyle(color: textSecondary, fontSize: 12)),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: textSecondary, size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
            
            // Appearance Section
            Text('Appearance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _buildThemeTile(icon: Icons.light_mode_rounded, title: 'Light Mode', isSelected: !isDark, textPrimary: textPrimary, textSecondary: textSecondary, onTap: () { if (isDark) ExpenseCalculatorApp.of(context)?.toggleTheme(); }),
                  Divider(height: 1, color: textSecondary.withOpacity(0.1)),
                  _buildThemeTile(icon: Icons.dark_mode_rounded, title: 'Dark Mode', isSelected: isDark, textPrimary: textPrimary, textSecondary: textSecondary, onTap: () { if (!isDark) ExpenseCalculatorApp.of(context)?.toggleTheme(); }),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // About Section
            Text('About', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _buildInfoTile(icon: Icons.info_outline_rounded, title: 'App Version', subtitle: '1.0.0', textPrimary: textPrimary, textSecondary: textSecondary),
                  Divider(height: 24, color: textSecondary.withOpacity(0.1)),
                  _buildInfoTile(icon: Icons.code_rounded, title: 'Developer', subtitle: 'Expense Tracker Team', textPrimary: textPrimary, textSecondary: textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // App Info Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expense Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 4),
                        Text('Track • Analyze • Save', style: TextStyle(fontSize: 14, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTile({required IconData icon, required String title, required bool isSelected, required Color textPrimary, required Color textSecondary, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : textSecondary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: isSelected ? AppTheme.primaryColor : textSecondary),
      ),
      title: Text(title, style: TextStyle(color: textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : Icon(Icons.circle_outlined, color: textSecondary.withOpacity(0.3)),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String subtitle, required Color textPrimary, required Color textSecondary}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.secondaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppTheme.secondaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: TextStyle(fontSize: 15, color: textPrimary, fontWeight: FontWeight.w500))),
        Text(subtitle, style: TextStyle(fontSize: 14, color: textSecondary)),
      ],
    );
  }
}
