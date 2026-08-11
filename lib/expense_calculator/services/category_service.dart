import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/app_config.dart';
import 'package:flutter/material.dart';

/// Category Model
class ExpenseCategory {
  final int id;
  final String name;
  final String icon;
  final Color color;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'],
      name: map['name'],
      icon: map['icon'] ?? '📦',
      color: _hexToColor(map['color'] ?? '#6B7280'),
    );
  }

  static Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}

/// Category Service - Fetches categories from API
class CategoryService {
  static List<ExpenseCategory>? _cachedCategories;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 10);

  /// Get all categories (with caching)
  static Future<List<ExpenseCategory>> getCategories({bool forceRefresh = false}) async {
    // Return cache if valid
    if (!forceRefresh && 
        _cachedCategories != null && 
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedCategories!;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/categories'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _cachedCategories = data.map((e) => ExpenseCategory.fromMap(e)).toList();
        _cacheTime = DateTime.now();
        return _cachedCategories!;
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
    
    // Return default categories if API fails
    return _getDefaultCategories();
  }

  /// Get category names list
  static Future<List<String>> getCategoryNames() async {
    final categories = await getCategories();
    return categories.map((c) => c.name).toList();
  }

  /// Get icon for category
  static Future<String> getIcon(String categoryName) async {
    final categories = await getCategories();
    final category = categories.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => ExpenseCategory(id: 0, name: 'Other', icon: '📦', color: Colors.grey),
    );
    return category.icon;
  }

  /// Get color for category
  static Future<Color> getColor(String categoryName) async {
    final categories = await getCategories();
    final category = categories.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => ExpenseCategory(id: 0, name: 'Other', icon: '📦', color: Colors.grey),
    );
    return category.color;
  }

  /// Get icons map (for quick access)
  static Future<Map<String, String>> getIconsMap() async {
    final categories = await getCategories();
    return {for (var c in categories) c.name: c.icon};
  }

  /// Get colors map (for quick access)
  static Future<Map<String, Color>> getColorsMap() async {
    final categories = await getCategories();
    return {for (var c in categories) c.name: c.color};
  }

  /// Default categories (fallback if API fails)
  static List<ExpenseCategory> _getDefaultCategories() {
    return [
      ExpenseCategory(id: 1, name: 'Food', icon: '🍔', color: const Color(0xFFFF6B6B)),
      ExpenseCategory(id: 2, name: 'Travel', icon: '✈️', color: const Color(0xFF4ECDC4)),
      ExpenseCategory(id: 3, name: 'Rent', icon: '🏠', color: const Color(0xFF45B7D1)),
      ExpenseCategory(id: 4, name: 'Shopping', icon: '🛍️', color: const Color(0xFFFF8ED4)),
      ExpenseCategory(id: 5, name: 'Bills', icon: '💳', color: const Color(0xFFF59E0B)),
      ExpenseCategory(id: 6, name: 'Entertainment', icon: '🎬', color: const Color(0xFF8B5CF6)),
      ExpenseCategory(id: 7, name: 'Health', icon: '💊', color: const Color(0xFF10B981)),
      ExpenseCategory(id: 8, name: 'Education', icon: '📚', color: const Color(0xFFEC4899)),
      ExpenseCategory(id: 9, name: 'Groceries', icon: '🛒', color: const Color(0xFF059669)),
      ExpenseCategory(id: 10, name: 'Fuel', icon: '⛽', color: const Color(0xFFEA580C)),
      ExpenseCategory(id: 11, name: 'Subscriptions', icon: '📺', color: const Color(0xFF6366F1)),
      ExpenseCategory(id: 12, name: 'Other', icon: '📦', color: const Color(0xFF6B7280)),
    ];
  }

  /// Clear cache
  static void clearCache() {
    _cachedCategories = null;
    _cacheTime = null;
  }
}
