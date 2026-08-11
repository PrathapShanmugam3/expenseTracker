import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../services/expense_service.dart';

import '../services/category_service.dart';
import 'monthwise_expense_screen.dart';

class YearwiseExpenseScreen extends StatefulWidget {
  final int userId;

  const YearwiseExpenseScreen({super.key, required this.userId});

  @override
  State<YearwiseExpenseScreen> createState() => _YearwiseExpenseScreenState();
}

class _YearwiseExpenseScreenState extends State<YearwiseExpenseScreen> {
  late ExpenseService _expenseService;
  int _selectedYear = DateTime.now().year;
  Map<int, double> _monthTotals = {};
  bool _isLoading = true;
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  
  String? _selectedCategory;
  Map<String, String> _categoryIcons = {};

  final List<String> _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  @override
  void initState() {
    super.initState();
    _expenseService = ExpenseService(userId: widget.userId);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _categoryIcons = await CategoryService.getIconsMap();
    
    // Fetch all expenses for the year to allow filtering
    final expenses = await _expenseService.getExpensesByYear(_selectedYear);
    
    // Filter locally
    var filteredExpenses = expenses;
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filteredExpenses = expenses.where((e) => e.category == _selectedCategory).toList();
    }

    // Aggregate by month
    Map<int, double> totals = {};
    for (var expense in filteredExpenses) {
      int month = expense.date.month;
      totals[month] = (totals[month] ?? 0) + expense.amount;
    }

    if (mounted) {
      setState(() {
        _monthTotals = totals;
        _isLoading = false;
      });
    }
  }

  double get _totalAmount => _monthTotals.values.fold(0.0, (sum, e) => sum + e);

  void _showFilterOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter by Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedCategory = null);
                        _loadData();
                        Navigator.pop(context);
                      },
                      child: const Text('Reset', style: TextStyle(color: AppTheme.primaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null || _selectedCategory == 'All',
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => _selectedCategory = 'All');
                            setState(() => _selectedCategory = 'All');
                          }
                        },
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(color: (_selectedCategory == null || _selectedCategory == 'All') ? Colors.white : textPrimary),
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      ),
                      const SizedBox(width: 8),
                      ..._categoryIcons.keys.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => _selectedCategory = cat);
                                setState(() => _selectedCategory = cat);
                              }
                            },
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : textPrimary),
                            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _loadData();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply Filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showYearPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final bgColor = isDark ? AppTheme.darkSurface : Colors.white;
    final currentYear = DateTime.now().year;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Year', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(6, (index) {
                final year = currentYear - 5 + index;
                final isSelected = year == _selectedYear;
                return GestureDetector(
                  onTap: () { setState(() => _selectedYear = year); Navigator.pop(context); _loadData(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppTheme.primaryColor : textPrimary.withOpacity(0.2)),
                    ),
                    child: Text('$year', style: TextStyle(fontSize: 16, color: isSelected ? Colors.white : textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(textPrimary, cardColor),
            _buildYearSelector(textPrimary, textSecondary, cardColor),
            _buildTotalCard(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : _monthTotals.isEmpty
                      ? _buildEmptyState(textSecondary)
                      : _buildMonthList(textPrimary, textSecondary, cardColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(Color textPrimary, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Text('Year-wise Expenses', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary)),
            ],
          ),
          GestureDetector(
            onTap: _showFilterOptions,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.filter_list_rounded, color: AppTheme.primaryColor, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector(Color textPrimary, Color textSecondary, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _showYearPicker,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Text('$_selectedYear', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down_rounded, color: textSecondary.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.accentColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Yearly Total', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
              const SizedBox(height: 8),
              Text(_currencyFormat.format(_totalAmount), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Text('${_monthTotals.length} months', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_rounded, size: 80, color: textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No expenses for this year', style: TextStyle(fontSize: 18, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMonthList(Color textPrimary, Color textSecondary, Color cardColor) {
    final maxAmount = _monthTotals.values.fold(0.0, (a, b) => a > b ? a : b);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final amount = _monthTotals[month] ?? 0.0;
        final progress = maxAmount > 0 ? amount / maxAmount : 0.0;
        final hasData = amount > 0;

        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => MonthwiseExpenseScreen(
                userId: widget.userId,
                initialYear: _selectedYear,
                initialMonth: month,
              ),
            ));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: hasData ? AppTheme.primaryColor.withOpacity(0.1) : textSecondary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text(_months[index].substring(0, 3), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: hasData ? AppTheme.primaryColor : textSecondary))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text(_months[index], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: hasData ? textPrimary : textSecondary))),
                    Text(_currencyFormat.format(amount), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: hasData ? AppTheme.primaryColor : textSecondary)),
                  ],
                ),
                if (hasData) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: progress, backgroundColor: textSecondary.withOpacity(0.1), valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor), minHeight: 6),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
