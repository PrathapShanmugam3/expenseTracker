import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../services/category_service.dart';
import 'expense_detail_screen.dart';

class DaywiseExpenseScreen extends StatefulWidget {
  final int userId;
  final DateTime? initialDate;

  const DaywiseExpenseScreen({super.key, required this.userId, this.initialDate});

  @override
  State<DaywiseExpenseScreen> createState() => _DaywiseExpenseScreenState();
}

class _DaywiseExpenseScreenState extends State<DaywiseExpenseScreen> {
  late ExpenseService _expenseService;
  late DateTime _selectedDate;
  List<Expense> _expenses = [];
  bool _isLoading = true;
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  String? _selectedCategory;
  String _sortOption = 'Newest First'; // Newest First, Oldest First, Amount High-Low, Amount Low-High
  Map<String, String> _categoryIcons = {};
  Map<String, Color> _categoryColors = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _expenseService = ExpenseService(userId: widget.userId);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _categoryIcons = await CategoryService.getIconsMap();
    _categoryColors = await CategoryService.getColorsMap();
    await _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    var expenses = await _expenseService.getExpensesByDate(_selectedDate);
    
    // Apply Category Filter
    if (_selectedCategory != null && _selectedCategory != 'All') {
      expenses = expenses.where((e) => e.category == _selectedCategory).toList();
    }

    // Apply Sorting
    switch (_sortOption) {
      case 'Newest First':
        expenses.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Oldest First':
        expenses.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Amount High-Low':
        expenses.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Amount Low-High':
        expenses.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    if (mounted) {
      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
    }
  }

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
                    Text('Filter & Sort', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = null;
                          _sortOption = 'Newest First';
                        });
                        _loadExpenses();
                        Navigator.pop(context);
                      },
                      child: const Text('Reset', style: TextStyle(color: AppTheme.primaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Sort By', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: ['Newest First', 'Oldest First', 'Amount High-Low', 'Amount Low-High'].map((option) {
                    final isSelected = _sortOption == option;
                    return ChoiceChip(
                      label: Text(option),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setModalState(() => _sortOption = option);
                          setState(() => _sortOption = option);
                        }
                      },
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : textPrimary),
                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 10),
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
                    child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Future<void> _selectDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppTheme.primaryColor,
                    onPrimary: Colors.white,
                    surface: AppTheme.darkSurface,
                    onSurface: AppTheme.darkTextPrimary,
                  )
                : const ColorScheme.light(
                    primary: AppTheme.primaryColor,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppTheme.lightTextPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadExpenses();
    }
  }

  double get _totalAmount => _expenses.fold(0.0, (sum, e) => sum + e.amount);

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
              _buildDateSelector(textPrimary, textSecondary, cardColor),
              _buildTotalCard(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                    : _expenses.isEmpty
                        ? _buildEmptyState(textSecondary)
                        : _buildExpenseList(textPrimary, textSecondary, cardColor),
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
              Text('Day-wise Expenses', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary)),
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

  Widget _buildDateSelector(Color textPrimary, Color textSecondary, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _selectDate,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Text(DateFormat('EEEE, d MMMM yyyy').format(_selectedDate), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
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
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Expenses', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
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
            child: Text('${_expenses.length} items', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
          Icon(Icons.receipt_long_rounded, size: 80, color: textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No expenses found', style: TextStyle(fontSize: 18, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildExpenseList(Color textPrimary, Color textSecondary, Color cardColor) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final expense = _expenses[index];
        final color = _categoryColors[expense.category] ?? AppTheme.primaryColor;
        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => ExpenseDetailScreen(expense: expense, userId: widget.userId)));
            if (result == true) {
              _hasChanges = true;
              _loadExpenses();
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(_categoryIcons[expense.category] ?? '📦', style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.category, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                      if (expense.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(expense.notes, style: TextStyle(fontSize: 13, color: textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                Text(_currencyFormat.format(expense.amount), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        );
      },
    );
  }
}
