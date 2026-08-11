import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_theme.dart';
import '../services/expense_service.dart';
import '../services/category_service.dart';

/// Category Summary Screen with Pie Chart
class CategorySummaryScreen extends StatefulWidget {
  final int userId;

  const CategorySummaryScreen({super.key, required this.userId});

  @override
  State<CategorySummaryScreen> createState() => _CategorySummaryScreenState();
}

class _CategorySummaryScreenState extends State<CategorySummaryScreen> {
  late ExpenseService _expenseService;
  Map<String, double> _categoryTotals = {};
  Map<String, String> _categoryIcons = {};
  Map<String, Color> _categoryColors = {};
  bool _isLoading = true;
  int _touchedIndex = -1;
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _expenseService = ExpenseService(userId: widget.userId);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Load categories from API
    _categoryIcons = await CategoryService.getIconsMap();
    _categoryColors = await CategoryService.getColorsMap();
    
    // Load category totals
    final totals = await _expenseService.getCategoryTotals();
    
    if (mounted) {
      setState(() {
        _categoryTotals = totals;
        _isLoading = false;
      });
    }
  }

  double get _totalAmount =>
      _categoryTotals.values.fold(0.0, (sum, e) => sum + e);

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
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : _categoryTotals.isEmpty
                      ? _buildEmptyState(textSecondary)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildTotalCard(),
                              const SizedBox(height: 24),
                              _buildPieChart(cardColor),
                              const SizedBox(height: 24),
                              _buildCategoryList(textPrimary, textSecondary, cardColor),
                            ],
                          ),
                        ),
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
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Category Summary',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Expenses',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(_totalAmount),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_categoryTotals.length} categories',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Color cardColor) {
    if (_categoryTotals.isEmpty) return const SizedBox();

    final categories = _categoryTotals.keys.toList();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  _touchedIndex = -1;
                  return;
                }
                _touchedIndex =
                    pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: List.generate(categories.length, (index) {
            final isTouched = index == _touchedIndex;
            final category = categories[index];
            final value = _categoryTotals[category]!;
            final percentage = (value / _totalAmount * 100).toStringAsFixed(1);
            final color = _categoryColors[category] ?? AppTheme.primaryColor;

            return PieChartSectionData(
              color: color,
              value: value,
              title: isTouched ? '$percentage%' : '',
              radius: isTouched ? 60 : 50,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              badgeWidget: isTouched
                  ? Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _categoryIcons[category] ?? '📦',
                        style: const TextStyle(fontSize: 20),
                      ),
                    )
                  : null,
              badgePositionPercentageOffset: 1.3,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_rounded,
            size: 80,
            color: textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No expense data available',
            style: TextStyle(
              fontSize: 18,
              color: textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(Color textPrimary, Color textSecondary, Color cardColor) {
    final sortedCategories = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...sortedCategories.map((entry) {
          final category = entry.key;
          final amount = entry.value;
          final percentage = amount / _totalAmount;
          final color = _categoryColors[category] ?? AppTheme.primaryColor;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _categoryIcons[category] ?? '📦',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            '${(percentage * 100).toStringAsFixed(1)}% of total',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _currencyFormat.format(amount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: textSecondary.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
