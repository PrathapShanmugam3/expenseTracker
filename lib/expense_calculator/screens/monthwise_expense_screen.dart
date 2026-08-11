import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';

import '../services/category_service.dart';
import 'daywise_expense_screen.dart';

class MonthwiseExpenseScreen extends StatefulWidget {
  final int userId;
  final int? initialYear;
  final int? initialMonth;

  const MonthwiseExpenseScreen({
    super.key, 
    required this.userId,
    this.initialYear,
    this.initialMonth,
  });

  @override
  State<MonthwiseExpenseScreen> createState() => _MonthwiseExpenseScreenState();
}

class _MonthwiseExpenseScreenState extends State<MonthwiseExpenseScreen> {
  late ExpenseService _expenseService;
  late int _selectedYear;
  late int _selectedMonth;
  List<Expense> _expenses = [];
  Map<int, double> _dayTotals = {};
  bool _isLoading = true;
  bool _hasChanges = false;
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  
  String? _selectedCategory;
  Map<String, String> _categoryIcons = {};

  final List<String> _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear ?? DateTime.now().year;
    _selectedMonth = widget.initialMonth ?? DateTime.now().month;
    _expenseService = ExpenseService(userId: widget.userId);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _categoryIcons = await CategoryService.getIconsMap();
    await _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    var expenses = await _expenseService.getExpensesByMonth(_selectedYear, _selectedMonth);
    
    // Apply Category Filter
    if (_selectedCategory != null && _selectedCategory != 'All') {
      expenses = expenses.where((e) => e.category == _selectedCategory).toList();
    }

    Map<int, double> dayTotals = {};
    for (var expense in expenses) {
      int day = expense.date.day;
      dayTotals[day] = (dayTotals[day] ?? 0) + expense.amount;
    }
    if (mounted) {
      setState(() {
        _expenses = expenses;
        _dayTotals = dayTotals;
        _isLoading = false;
      });
    }
  }

  double get _totalAmount => _expenses.fold(0.0, (sum, e) => sum + e.amount);

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
                        _loadExpenses();
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
                      _loadExpenses();
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

  void _showMonthPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final bgColor = isDark ? AppTheme.darkSurface : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Month', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () { setState(() => _selectedYear--); Navigator.pop(context); _showMonthPicker(); }, icon: Icon(Icons.chevron_left, color: textPrimary)),
                Text('$_selectedYear', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                IconButton(onPressed: () { setState(() => _selectedYear++); Navigator.pop(context); _showMonthPicker(); }, icon: Icon(Icons.chevron_right, color: textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(12, (index) {
                final isSelected = index + 1 == _selectedMonth;
                return GestureDetector(
                  onTap: () { setState(() => _selectedMonth = index + 1); Navigator.pop(context); _loadExpenses(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppTheme.primaryColor : textPrimary.withOpacity(0.2)),
                    ),
                    child: Text(_months[index].substring(0, 3), style: TextStyle(color: isSelected ? Colors.white : textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
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

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(textPrimary, cardColor),
              _buildMonthSelector(textPrimary, textSecondary, cardColor),
              _buildTotalCard(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                    : _dayTotals.isEmpty
                        ? _buildEmptyState(textSecondary)
                        : _buildDayList(textPrimary, textSecondary, cardColor),
              ),
            ],
          ),
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
                onTap: () => Navigator.pop(context, _hasChanges),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Text('Month-wise Expenses', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary)),
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

  Widget _buildMonthSelector(Color textPrimary, Color textSecondary, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _showMonthPicker,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Text('${_months[_selectedMonth - 1]} $_selectedYear', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
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
        gradient: AppTheme.secondaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.secondaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Total', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(_currencyFormat.format(_totalAmount), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Text('${_dayTotals.length} days', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
          Icon(Icons.calendar_month_rounded, size: 80, color: textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No expenses for this month', style: TextStyle(fontSize: 18, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDayList(Color textPrimary, Color textSecondary, Color cardColor) {
    final sortedDays = _dayTotals.keys.toList()..sort((a, b) => b.compareTo(a));
    final maxAmount = _dayTotals.values.fold(0.0, (a, b) => a > b ? a : b);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final amount = _dayTotals[day]!;
        final date = DateTime(_selectedYear, _selectedMonth, day);
        final progress = maxAmount > 0 ? amount / maxAmount : 0.0;

        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(context, MaterialPageRoute(
              builder: (context) => DaywiseExpenseScreen(
                userId: widget.userId,
                initialDate: date,
              ),
            ));
            // Note: DaywiseExpenseScreen currently defaults to today. 
            // Ideally we should pass the selected date to it.
            // But since DaywiseExpenseScreen has its own date picker, it's okay for now.
            // Wait, if I click a specific day, I expect to see THAT day.
            // I should update DaywiseExpenseScreen to accept an initial date.
            
            // However, for now, let's just handle the result.
            if (result == true) {
              _hasChanges = true;
              _loadExpenses();
            }
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
                      decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text('$day', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('EEEE').format(date), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                          Text(DateFormat('d MMM yyyy').format(date), style: TextStyle(fontSize: 13, color: textSecondary)),
                        ],
                      ),
                    ),
                    Text(_currencyFormat.format(amount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: progress, backgroundColor: textSecondary.withOpacity(0.1), valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor), minHeight: 6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
