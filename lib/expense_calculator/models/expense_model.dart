/// Expense Model for Daily Expense Calculator
class Expense {
  int? id;
  double amount;
  String category;
  DateTime date;
  String notes;

  Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.notes = '',
  });

  /// Convert Expense to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  /// Create Expense from Map (SQLite)
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: double.parse(map['amount'].toString()),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String? ?? '',
    );
  }

  /// Copy with method for updating expense
  Expense copyWith({
    int? id,
    double? amount,
    String? category,
    DateTime? date,
    String? notes,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}

/// Predefined expense categories
class ExpenseCategories {
  static const List<String> categories = [
    'Food',
    'Travel',
    'Rent',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Education',
    'Groceries',
    'Fuel',
    'Subscriptions',
    'Other',
  ];

  static const Map<String, String> icons = {
    'Food': '🍔',
    'Travel': '✈️',
    'Rent': '🏠',
    'Shopping': '🛍️',
    'Bills': '💳',
    'Entertainment': '🎬',
    'Health': '💊',
    'Education': '📚',
    'Groceries': '🛒',
    'Fuel': '⛽',
    'Subscriptions': '📺',
    'Other': '📦',
  };
}
