import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/app_theme.dart';
import '../utils/app_config.dart';

/// Admin Panel Screen - Manage categories and users
class AdminPanelScreen extends StatefulWidget {
  final int userId;

  const AdminPanelScreen({super.key, required this.userId});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingUsers = true;
  bool _isLoadingCategories = true;

  final Map<int, String> _roleNames = {1: 'User', 2: 'Moderator', 3: 'Admin'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadUsers(), _loadCategories()]);
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/auth/users'),
        headers: {'x-user-id': widget.userId.toString()},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => _users = data.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      print('Error loading users: $e');
    }
    setState(() => _isLoadingUsers = false);
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/categories'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => _categories = data.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
    setState(() => _isLoadingCategories = false);
  }

  Future<void> _updateUserRole(int userId, int newRoleId) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/auth/users/$userId/role'),
        headers: {'Content-Type': 'application/json', 'x-user-id': widget.userId.toString()},
        body: jsonEncode({'roleId': newRoleId}),
      );
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Role updated'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
        );
        _loadUsers();
      }
    } catch (e) {
      print('Error updating role: $e');
    }
  }

  Future<void> _deleteUser(int userId) async {
    final confirmed = await _showConfirmDialog('Delete User', 'Are you sure you want to delete this user?');
    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/auth/users/$userId'),
        headers: {'x-user-id': widget.userId.toString()},
      );
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('User deleted'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
        );
        _loadUsers();
      }
    } catch (e) {
      print('Error deleting user: $e');
    }
  }

  Future<void> _addCategory() async {
    final result = await _showCategoryDialog();
    if (result == null) return;

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/categories'),
        headers: {'Content-Type': 'application/json', 'x-user-id': widget.userId.toString()},
        body: jsonEncode(result),
      );
      if (response.statusCode == 201 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Category added'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
        );
        _loadCategories();
      }
    } catch (e) {
      print('Error adding category: $e');
    }
  }

  Future<void> _editCategory(Map<String, dynamic> category) async {
    final result = await _showCategoryDialog(category: category);
    if (result == null) return;

    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/categories/${category['id']}'),
        headers: {'Content-Type': 'application/json', 'x-user-id': widget.userId.toString()},
        body: jsonEncode(result),
      );
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Category updated'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
        );
        _loadCategories();
      }
    } catch (e) {
      print('Error updating category: $e');
    }
  }

  Future<void> _deleteCategory(int categoryId) async {
    final confirmed = await _showConfirmDialog('Delete Category', 'Are you sure you want to delete this category?');
    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/categories/$categoryId'),
        headers: {'x-user-id': widget.userId.toString()},
      );
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Category deleted'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
        );
        _loadCategories();
      }
    } catch (e) {
      print('Error deleting category: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(textPrimary, cardColor),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: textPrimary.withOpacity(0.5),
                indicatorColor: AppTheme.primaryColor,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(icon: Icon(Icons.category_rounded), text: 'Categories'),
                  Tab(icon: Icon(Icons.people_rounded), text: 'Users'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoriesTab(textPrimary, cardColor),
                  _buildUsersTab(textPrimary, cardColor),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _addCategory,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Text('Admin Panel', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text('Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(Color textPrimary, Color cardColor) {
    if (_isLoadingCategories) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: _hexToColor(category['color']).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(category['icon'] ?? '📦', style: const TextStyle(fontSize: 22))),
            ),
            title: Text(category['name'], style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
            subtitle: Text(category['color'] ?? '#6B7280', style: TextStyle(color: textPrimary.withOpacity(0.5), fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: Icon(Icons.edit, color: AppTheme.primaryColor), onPressed: () => _editCategory(category)),
                IconButton(icon: const Icon(Icons.delete, color: AppTheme.error), onPressed: () => _deleteCategory(category['id'])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsersTab(Color textPrimary, Color cardColor) {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final roleId = user['role_id'] ?? 1;
        final isCurrentUser = user['id'] == widget.userId;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: roleId == 3 ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                roleId == 3 ? Icons.admin_panel_settings : Icons.person,
                color: roleId == 3 ? AppTheme.primaryColor : Colors.grey,
              ),
            ),
            title: Text(user['email'], style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
            subtitle: Text(_roleNames[roleId] ?? 'User', style: TextStyle(color: roleId == 3 ? AppTheme.primaryColor : textPrimary.withOpacity(0.5), fontSize: 12)),
            trailing: isCurrentUser
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('You', style: TextStyle(color: AppTheme.success, fontSize: 12)),
                  )
                : PopupMenuButton<int>(
                    icon: Icon(Icons.more_vert, color: textPrimary),
                    onSelected: (value) {
                      if (value == -1) {
                        _deleteUser(user['id']);
                      } else {
                        _updateUserRole(user['id'], value);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 1, child: Text('Set as User')),
                      const PopupMenuItem(value: 2, child: Text('Set as Moderator')),
                      const PopupMenuItem(value: 3, child: Text('Set as Admin')),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: -1, child: Text('Delete User', style: TextStyle(color: AppTheme.error))),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showCategoryDialog({Map<String, dynamic>? category}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: category?['name'] ?? '');
    final iconController = TextEditingController(text: category?['icon'] ?? '📦');
    final colorController = TextEditingController(text: category?['color'] ?? '#6B7280');

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: iconController, decoration: const InputDecoration(labelText: 'Icon (emoji)')),
            const SizedBox(height: 12),
            TextField(controller: colorController, decoration: const InputDecoration(labelText: 'Color (#hex)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () => Navigator.pop(context, {
              'name': nameController.text,
              'icon': iconController.text,
              'color': colorController.text,
            }),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String? hex) {
    if (hex == null) return Colors.grey;
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
