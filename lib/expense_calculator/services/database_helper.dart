import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense_model.dart';

/// SQLite Database Helper for Expense Calculator
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_calculator.db');
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Create database tables
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expense (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');
  }

  /// Insert new expense
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expense', expense.toMap());
  }

  /// Get all expenses
  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final result = await db.query('expense', orderBy: 'date DESC');
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  /// Get expenses by date
  Future<List<Expense>> getExpensesByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final result = await db.query(
      'expense',
      where: "date LIKE ?",
      whereArgs: ['$dateStr%'],
      orderBy: 'date DESC',
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  /// Get expenses by month
  Future<List<Expense>> getExpensesByMonth(int year, int month) async {
    final db = await database;
    final monthStr = month.toString().padLeft(2, '0');
    final result = await db.query(
      'expense',
      where: "date LIKE ?",
      whereArgs: ['$year-$monthStr%'],
      orderBy: 'date DESC',
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  /// Get expenses by year
  Future<List<Expense>> getExpensesByYear(int year) async {
    final db = await database;
    final result = await db.query(
      'expense',
      where: "date LIKE ?",
      whereArgs: ['$year%'],
      orderBy: 'date DESC',
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  /// Update expense
  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expense',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  /// Delete expense
  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
      'expense',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get today's total
  Future<double> getTodayTotal() async {
    final today = DateTime.now();
    final expenses = await getExpensesByDate(today);
    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  /// Get this month's total
  Future<double> getMonthTotal() async {
    final now = DateTime.now();
    final expenses = await getExpensesByMonth(now.year, now.month);
    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  /// Get this year's total
  Future<double> getYearTotal() async {
    final now = DateTime.now();
    final expenses = await getExpensesByYear(now.year);
    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  /// Get category-wise totals
  Future<Map<String, double>> getCategoryTotals() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total 
      FROM expense 
      GROUP BY category 
      ORDER BY total DESC
    ''');
    
    Map<String, double> categoryTotals = {};
    for (var row in result) {
      categoryTotals[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return categoryTotals;
  }

  /// Get day-wise totals for a month
  Future<Map<int, double>> getDayWiseTotalsForMonth(int year, int month) async {
    final expenses = await getExpensesByMonth(year, month);
    Map<int, double> dayTotals = {};
    
    for (var expense in expenses) {
      int day = expense.date.day;
      dayTotals[day] = (dayTotals[day] ?? 0) + expense.amount;
    }
    return dayTotals;
  }

  /// Get month-wise totals for a year
  Future<Map<int, double>> getMonthWiseTotalsForYear(int year) async {
    final expenses = await getExpensesByYear(year);
    Map<int, double> monthTotals = {};
    
    for (var expense in expenses) {
      int month = expense.date.month;
      monthTotals[month] = (monthTotals[month] ?? 0) + expense.amount;
    }
    return monthTotals;
  }

  /// Close database
  Future close() async {
    final db = await database;
    db.close();
  }
}
