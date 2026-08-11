import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../services/category_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final int userId;
  final Expense? expense;

  const AddExpenseScreen({super.key, required this.userId, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool get _isEditing => widget.expense != null && widget.expense!.id != null;
  
  late ExpenseService _expenseService;
  List<String> _categories = [];
  Map<String, String> _categoryIcons = {};
  Map<String, Color> _categoryColors = {};

  @override
  void initState() {
    super.initState();
    _expenseService = ExpenseService(userId: widget.userId);
    _loadCategories();
    
    if (widget.expense != null) {
      _amountController.text = widget.expense!.amount.toString();
      _selectedCategory = widget.expense!.category;
      _selectedDate = widget.expense!.date;
      _notesController.text = widget.expense!.notes;
    }
  }

  Future<void> _loadCategories() async {
    final names = await CategoryService.getCategoryNames();
    _categoryIcons = await CategoryService.getIconsMap();
    _categoryColors = await CategoryService.getColorsMap();
    if (mounted) {
      setState(() {
        _categories = names;
        if (!_isEditing && _categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
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
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final expense = Expense(
      id: widget.expense?.id,
      amount: double.parse(_amountController.text),
      category: _selectedCategory,
      date: _selectedDate,
      notes: _notesController.text.trim(),
    );

    bool success;
    if (_isEditing) {
      success = await _expenseService.updateExpense(expense);
    } else {
      final result = await _expenseService.addExpense(expense);
      success = result != null;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Expense updated!' : 'Expense saved!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save expense'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAmountInput(textPrimary),
                      const SizedBox(height: 30),
                      _buildCategorySection(textPrimary, cardColor),
                      const SizedBox(height: 30),
                      _buildDateSection(textPrimary, textSecondary, cardColor),
                      const SizedBox(height: 30),
                      _buildNotesSection(textPrimary, textSecondary, cardColor),
                      const SizedBox(height: 40),
                      _buildSaveButton(),
                    ],
                  ),
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
              child: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _isEditing ? 'Edit Expense' : 'Add Expense',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(Color textPrimary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Text('₹', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  cursorColor: Colors.white,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.white54, fontSize: 40, fontWeight: FontWeight.bold),
                    border: InputBorder.none,
                    errorStyle: TextStyle(color: Colors.yellow),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter amount';
                    if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Enter valid amount';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(Color textPrimary, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _categories.map((category) {
            final isSelected = category == _selectedCategory;
            final color = _categoryColors[category] ?? AppTheme.primaryColor;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? color : cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 2),
                  boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_categoryIcons[category] ?? '📦', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(category, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : textPrimary)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSection(Color textPrimary, Color textSecondary, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.secondaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.calendar_today_rounded, color: AppTheme.secondaryColor),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEEE').format(_selectedDate), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 4),
                    Text(DateFormat('d MMMM, yyyy').format(_selectedDate), style: TextStyle(fontSize: 14, color: textSecondary)),
                  ],
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, color: textSecondary.withOpacity(0.5), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(Color textPrimary, Color textSecondary, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
          child: TextFormField(
            controller: _notesController,
            maxLines: 3,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'Add a note...',
              hintStyle: TextStyle(color: textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveExpense,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isEditing ? Icons.check_rounded : Icons.save_rounded),
                  const SizedBox(width: 8),
                  Text(_isEditing ? 'Update Expense' : 'Save Expense', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }
}
