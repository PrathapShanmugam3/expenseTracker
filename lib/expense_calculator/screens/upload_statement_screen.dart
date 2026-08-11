import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../services/statement_parser_service.dart';
import '../services/expense_service.dart';
import '../models/expense_model.dart';
import '../utils/app_theme.dart';

class UploadStatementScreen extends StatefulWidget {
  final int userId;

  const UploadStatementScreen({super.key, required this.userId});

  @override
  State<UploadStatementScreen> createState() => _UploadStatementScreenState();
}

class _UploadStatementScreenState extends State<UploadStatementScreen> {
  bool _isLoading = false;
  late ExpenseService _expenseService;

  @override
  void initState() {
    super.initState();
    _expenseService = ExpenseService(userId: widget.userId);
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'pdf'],
        withData: kIsWeb,
      );

      if (result != null) {
        final file = result.files.single;
        
        // Check if PDF and ask for password if needed
        if (file.name.toLowerCase().endsWith('.pdf')) {
          // Check if actually protected
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Checking file security...'),
                duration: Duration(seconds: 1),
              ),
            );
          }
          
          final isProtected = await StatementParserService.isPdfPasswordProtected(file);
          
          if (isProtected) {
            _showPasswordDialog(file);
          } else {
            _startUpload(file, null);
          }
        } else {
          _startUpload(file, null);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  void _showPasswordDialog(PlatformFile file) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('If your bank statement is password protected, please enter it below. Otherwise, leave blank.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password (Optional)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startUpload(file, null);
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startUpload(file, passwordController.text);
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  void _startUpload(PlatformFile file, String? password) {
    // 1. Show message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading statement in background...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // 2. Pop immediately
      Navigator.pop(context);
    }

    // 3. Run upload in background (fire and forget)
    _uploadInBackground(file, password);
  }

  Future<void> _uploadInBackground(PlatformFile file, String? password) async {
    try {
      debugPrint("[Upload] Starting background upload for ${file.name}");
      final response = await StatementParserService.uploadStatement(file, widget.userId, password: password);
      
      debugPrint("[Upload] Success: ${response['inserted']} inserted");
      
      // Notify Dashboard to refresh
      ExpenseService.shouldRefreshDashboard.value = !ExpenseService.shouldRefreshDashboard.value;

    } catch (e) {
      debugPrint("[Upload] Background upload failed: $e");
    }
  }

  void _showDownloadGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'How to Download Statements',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildGuideItem(
                      context,
                      'PhonePe',
                      Icons.phone_android,
                      Colors.purple,
                      [
                        'Open PhonePe App',
                        'Go to "History" tab (bottom right)',
                        'Tap on "Download Statement" (top right)',
                        'Select Date Range',
                        'Click "Proceed" -> "Download PDF"',
                        'Note: PhonePe only supports PDF format',
                      ],
                      screenshotPath: 'assets/guide_images/phonepe_statement.png',
                    ),
                    _buildGuideItem(
                      context,
                      'Google Pay',
                      Icons.g_mobiledata,
                      Colors.blue,
                      [
                        'Open Google Pay app or web',
                        'Tap on Profile Picture (top right)',
                        'Select "Settings" -> "Privacy & Security"',
                        'Tap "See all activity"',
                        'Click the download icon (top right)',
                        'Select date range and download PDF',
                        'Note: Google Pay provides PDF statements',
                      ],
                      screenshotPath: 'assets/guide_images/gpay_statement.png',
                    ),
                    _buildGuideItem(
                      context,
                      'Paytm',
                      Icons.account_balance_wallet,
                      Colors.lightBlue,
                      [
                        'Open Paytm App',
                        'Tap on Profile icon (top left)',
                        'Go to "UPI & Payment Settings"',
                        'Select "Download UPI Statement"',
                        'Choose date range (max 6 months)',
                        'Click "Download" - PDF will be downloaded',
                        'Note: Paytm provides PDF with transaction tags',
                      ],
                      screenshotPath: 'assets/guide_images/paytm_statement.png',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideItem(BuildContext context, String title, IconData icon, Color color, List<String> steps, {String? screenshotPath}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (screenshotPath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                screenshotPath,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your statement should look similar to this',
                      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...steps.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key + 1}. ',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(color: textPrimary.withOpacity(0.8)),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Statement'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'How to download?',
            onPressed: _showDownloadGuide,
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Uploading & Processing...', style: TextStyle(color: textPrimary)),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 80, color: AppTheme.primaryColor),
                  const SizedBox(height: 24),
                  Text(
                    'Upload Bank Statement',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Supported: PDF & CSV',
                    style: TextStyle(fontSize: 16, color: textPrimary.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Select File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _showDownloadGuide,
                    icon: const Icon(Icons.info_outline),
                    label: const Text('How to download statements?'),
                  ),
                ],
              ),
      ),
    );
  }
}
