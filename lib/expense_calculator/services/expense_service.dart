import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/expense_model.dart';
import '../utils/app_config.dart';

/// API Service for Expense Calculator
class ExpenseService {
  final int userId;

  ExpenseService({required this.userId});

  String get baseUrl => AppConfig.baseUrl;

  /// Notifier to trigger dashboard refresh
  static final ValueNotifier<bool> shouldRefreshDashboard = ValueNotifier(false);

  /// Add new expense
  Future<Expense?> addExpense(Expense expense) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/expenses'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'userId': userId,
          'amount': expense.amount,
          'category': expense.category,
          'date': expense.date.toIso8601String(),
          'notes': expense.notes,
        }),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Expense.fromMap(data);
      }
    } catch (e) {
      print('Error adding expense: $e');
    }
    return null;
  }

  /// Get all expenses
  Future<List<Expense>> getAllExpenses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expenses/$userId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Expense.fromMap(e)).toList();
      }
    } catch (e) {
      print('Error fetching expenses: $e');
    }
    return [];
  }

  /// Get expenses by date
  Future<List<Expense>> getExpensesByDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().substring(0, 10);
      final response = await http.get(
        Uri.parse('$baseUrl/expenses/$userId/date/$dateStr'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Expense.fromMap(e)).toList();
      }
    } catch (e) {
      print('Error fetching expenses by date: $e');
    }
    return [];
  }

  /// Get expenses by month
  Future<List<Expense>> getExpensesByMonth(int year, int month) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expenses/$userId/month/$year/$month'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Expense.fromMap(e)).toList();
      }
    } catch (e) {
      print('Error fetching expenses by month: $e');
    }
    return [];
  }

  /// Get expenses by year
  Future<List<Expense>> getExpensesByYear(int year) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expenses/$userId/year/$year'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Expense.fromMap(e)).toList();
      }
    } catch (e) {
      print('Error fetching expenses by year: $e');
    }
    return [];
  }

  /// Get summary totals
  Future<Map<String, double>> getSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expenses/$userId/summary'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'today': double.parse(data['today'].toString()),
          'month': double.parse(data['month'].toString()),
          'year': double.parse(data['year'].toString()),
        };
      }
    } catch (e) {
      print('Error fetching summary: $e');
    }
    return {'today': 0, 'month': 0, 'year': 0};
  }

  /// Get category totals
  Future<Map<String, double>> getCategoryTotals() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expenses/$userId/categories'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        Map<String, double> result = {};
        for (var item in data) {
          result[item['category']] = double.parse(item['total'].toString());
        }
        return result;
      }
    } catch (e) {
      print('Error fetching category totals: $e');
    }
    return {};
  }

  /// Get month-wise totals for a year
  Future<Map<int, double>> getMonthWiseTotals(int year) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expenses/$userId/monthwise/$year'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        Map<int, double> result = {};
        for (var item in data) {
          result[item['month'] as int] = double.parse(item['total'].toString());
        }
        return result;
      }
    } catch (e) {
      print('Error fetching month-wise totals: $e');
    }
    return {};
  }

  /// Update expense
  Future<bool> updateExpense(Expense expense) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/expenses/${expense.id}'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'amount': expense.amount,
          'category': expense.category,
          'date': expense.date.toIso8601String(),
          'notes': expense.notes,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating expense: $e');
    }
    return false;
  }

  /// Delete expense
  Future<bool> deleteExpense(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/expenses/$id'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting expense: $e');
    }
    return false;
  }
}
