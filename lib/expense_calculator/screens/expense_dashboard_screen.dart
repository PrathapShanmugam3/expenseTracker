import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../services/expense_service.dart';
import 'add_expense_screen.dart';
import 'daywise_expense_screen.dart';
import 'monthwise_expense_screen.dart';
import 'yearwise_expense_screen.dart';
import 'category_summary_screen.dart';
import 'expense_login_screen.dart';
import 'settings_screen.dart';
import 'account_screen.dart';
import 'upload_statement_screen.dart';
import '../models/expense_model.dart';

/// Dashboard Screen - Main home with bottom navigation
class ExpenseDashboardScreen extends StatefulWidget {
  final int userId;

  const ExpenseDashboardScreen({super.key, required this.userId});

  @override
  State<ExpenseDashboardScreen> createState() => _ExpenseDashboardScreenState();
}

class _ExpenseDashboardScreenState extends State<ExpenseDashboardScreen> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _HomeTab(userId: widget.userId),
      AccountScreen(userId: widget.userId),
      SettingsScreen(userId: widget.userId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.person_rounded, 'Account'),
                _buildNavItem(2, Icons.settings_rounded, 'Settings'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddExpenseScreen(userId: widget.userId),
                    ),
                  );
                  if (result == true) {
                    setState(() {
                      _pages[0] = _HomeTab(userId: widget.userId, key: UniqueKey());
                    });
                  }
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            )
          : null,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home Tab Content
class _HomeTab extends StatefulWidget {
  final int userId;

  const _HomeTab({super.key, required this.userId});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  late ExpenseService _expenseService;
  Map<String, double> _summary = {'today': 0, 'month': 0, 'year': 0};
  bool _isLoading = true;
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _expenseService = ExpenseService(userId: widget.userId);
    _loadSummary();
    
    // Listen for background refresh events
    ExpenseService.shouldRefreshDashboard.addListener(_onRefreshTriggered);
  }

  @override
  void dispose() {
    ExpenseService.shouldRefreshDashboard.removeListener(_onRefreshTriggered);
    super.dispose();
  }

  void _onRefreshTriggered() {
    debugPrint("[Dashboard] Refresh triggered by background event");
    _loadSummary();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Statement processed! Dashboard updated.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    final summary = await _expenseService.getSummary();
    if (mounted) {
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadSummary,
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(textPrimary, textSecondary),
              const SizedBox(height: 30),
              _buildSummarySection(textPrimary),
              const SizedBox(height: 30),
              _buildQuickActions(textPrimary, cardColor),
              const SizedBox(height: 30),
              _buildMenuOptions(textPrimary, textSecondary, cardColor),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Expense Tracker',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummarySection(Color textPrimary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : Column(
                children: [
                  _buildMainSummaryCard(
                    'Today\'s Expenses',
                    _summary['today'] ?? 0,
                    Icons.today_rounded,
                    AppTheme.primaryGradient,
                    DateFormat('EEEE, d MMM').format(DateTime.now()),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSmallSummaryCard(
                          'This Month',
                          _summary['month'] ?? 0,
                          Icons.calendar_month_rounded,
                          AppTheme.secondaryGradient,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSmallSummaryCard(
                          'This Year',
                          _summary['year'] ?? 0,
                          Icons.calendar_today_rounded,
                          AppTheme.accentGradient,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildMainSummaryCard(
    String title,
    double amount,
    IconData icon,
    LinearGradient gradient,
    String subtitle,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _currencyFormat.format(amount),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSummaryCard(
    String title,
    double amount,
    IconData icon,
    LinearGradient gradient,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _currencyFormat.format(amount),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Color textPrimary, Color cardColor) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildActionButton(
              _buildDynamicCalendarIcon(
                DateFormat('MMM').format(now).toUpperCase(),
                DateFormat('d').format(now),
              ),
              'Day',
              textPrimary,
              cardColor,
              () async {
                final result = await Navigator.push(context, MaterialPageRoute(
                  builder: (context) => DaywiseExpenseScreen(userId: widget.userId),
                ));
                if (result == true) _loadSummary();
              },
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(
              _buildDynamicCalendarIcon(
                DateFormat('yyyy').format(now),
                DateFormat('MMM').format(now),
                isMonth: true,
              ),
              'Month',
              textPrimary,
              cardColor,
              () async {
                final result = await Navigator.push(context, MaterialPageRoute(
                  builder: (context) => MonthwiseExpenseScreen(userId: widget.userId),
                ));
                if (result == true) _loadSummary();
              },
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(
              const Icon(Icons.bar_chart_rounded, size: 32, color: AppTheme.primaryColor),
              'Year',
              textPrimary,
              cardColor,
              () async {
                await Navigator.push(context, MaterialPageRoute(
                  builder: (context) => YearwiseExpenseScreen(userId: widget.userId),
                ));
              },
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(Widget icon, String label, Color textPrimary, Color cardColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(height: 40, width: 40, child: Center(child: icon)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicCalendarIcon(String topText, String bottomText, {bool isMonth = false}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isMonth ? AppTheme.secondaryColor : AppTheme.error,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            alignment: Alignment.center,
            child: Text(
              topText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                bottomText,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions(Color textPrimary, Color textSecondary, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildMenuTile(
          'Category Summary',
          'View expenses by category',
          Icons.pie_chart_rounded,
          AppTheme.primaryColor,
          textPrimary,
          textSecondary,
          cardColor,
          () => Navigator.push(context, MaterialPageRoute(
            builder: (context) => CategorySummaryScreen(userId: widget.userId),
          )),
        ),
        const SizedBox(height: 12),
        _buildMenuTile(
          'Upload Statement',
          'Import expenses from CSV',
          Icons.upload_file_rounded,
          AppTheme.secondaryColor,
          textPrimary,
          textSecondary,
          cardColor,
          () => Navigator.push(context, MaterialPageRoute(
            builder: (context) => UploadStatementScreen(userId: widget.userId),
          )).then((result) {
            // Refresh summary after import if changes occurred
            if (result == true) _loadSummary();
          }),
        ),
      ],
    );
  }

  Widget _buildMenuTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Color textPrimary,
    Color textSecondary,
    Color cardColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: textSecondary.withOpacity(0.5), size: 18),
          ],
        ),
      ),
    );
  }
}
