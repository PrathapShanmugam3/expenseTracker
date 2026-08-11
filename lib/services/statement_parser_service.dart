import 'dart:io';
import 'package:csv/csv.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../expense_calculator/models/expense_model.dart';

class StatementParserService {
  /// Parse a statement file (PDF or CSV)
  static Future<List<Expense>> parseStatement(File file) async {
    final fileName = file.path.toLowerCase();
    
    if (fileName.endsWith('.pdf')) {
      return _parsePdf(file);
    } else if (fileName.endsWith('.csv')) {
      return _parseCsv(file);
    } else {
      throw Exception('Unsupported file format. Please upload a PDF or CSV file.');
    }
  }

  /// Parse PDF file
  static Future<List<Expense>> _parsePdf(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      
      final buffer = StringBuffer();
      for (int i = 0; i < document.pages.count; i++) {
        final textExtractor = PdfTextExtractor(document);
        buffer.write(textExtractor.extractText(startPageIndex: i, endPageIndex: i));
      }
      
      document.dispose();
      
      final text = buffer.toString();
      return _extractExpensesFromText(text);
    } catch (e) {
      print('PDF Parse Error: $e');
      throw Exception('Failed to parse PDF: $e');
    }
  }

  /// Parse CSV file
  static Future<List<Expense>> _parseCsv(File file) async {
    try {
      final content = await file.readAsString();
      final rows = const CsvToListConverter().convert(content);
      
      return _parseCsvRows(rows);
    } catch (e) {
      print('CSV Parse Error: $e');
      throw Exception('Failed to parse CSV: $e');
    }
  }

  /// Extract expenses from PDF text
  static List<Expense> _extractExpensesFromText(String text) {
    final expenses = <Expense>[];
    final lines = text.split('\n');
    final dateStartRegex = RegExp(r'^\d{2}[-/]\d{2}[-/]\d{4}|\d{1,2}\s+[A-Za-z]+,?\s+\d{4}|[A-Za-z]+\s+\d{1,2},?\s+\d{4}|\d{1,2}\s+[A-Za-z]{3}');
    
    List<String> transactionBuffer = [];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      if (dateStartRegex.hasMatch(trimmed)) {
        if (transactionBuffer.isNotEmpty) {
          _processTransactionBlock(transactionBuffer, expenses);
          transactionBuffer = [];
        }
        transactionBuffer.add(trimmed);
      } else if (transactionBuffer.isNotEmpty) {
        transactionBuffer.add(trimmed);
      }
    }
    
    if (transactionBuffer.isNotEmpty) {
      _processTransactionBlock(transactionBuffer, expenses);
    }
    
    return expenses;
  }

  /// Process a transaction block from PDF
  static void _processTransactionBlock(List<String> block, List<Expense> expenses) {
    if (block.isEmpty) return;
    
    final fullText = block.join(' ');
    final dateRegex = RegExp(r'\d{2}[-/]\d{2}[-/]\d{4}|\d{1,2}\s+[A-Za-z]+,?\s+\d{4}|[A-Za-z]+\s+\d{1,2},?\s+\d{4}|\d{1,2}\s+[A-Za-z]{3}');
    final dateMatch = dateRegex.firstMatch(block[0]);
    
    if (dateMatch == null) return;
    
    final date = _parseDate(dateMatch.group(0)!);
    if (date == null) return;
    
    // Extract amounts
    final amountRegex = RegExp(r'(?:₹|Rs\.?|INR|INR\s)\s*([\d,]+(?:\.\d{1,2})?)');
    final amounts = amountRegex.allMatches(fullText)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '')) ?? 0.0)
        .where((amt) => amt > 0)
        .toList();
    
    bool isDebit = false;
    double amount = 0.0;
    String description = '';
    String category = 'Other';
    
    // Check for debit indicators
    final paidToRegex = RegExp(r'(?:Paid to|Sent to|Money Sent to|Paid Successfully to)\s+(.+?)(?:\s+(?:DEBIT|CREDIT|₹|Rs|INR|Transaction|Txn|Ref)|$)');
    final paidToMatch = paidToRegex.firstMatch(fullText);
    
    if (paidToMatch != null) {
      isDebit = true;
      description = paidToMatch.group(1)!.trim();
      // Clean up description
      description = description.split('Transaction ID')[0].trim();
      description = description.split('Txn ID')[0].trim();
      description = description.split('Ref No')[0].trim();
    } else if (fullText.contains('Received from')) {
      return; // Skip credit transactions
    } else if (fullText.contains('Debited from') || fullText.toUpperCase().contains('DEBIT')) {
      isDebit = true;
      description = 'Debit Transaction';
    }
    
    if (amounts.isNotEmpty) {
      amount = amounts.first;
    }
    
    if (!isDebit || amount == 0) return;
    
    if (description.isEmpty || description == 'Debit Transaction') {
      description = 'Expense';
    }
    
    description = description.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (description.length > 50) {
      description = description.substring(0, 50);
    }
    
    expenses.add(Expense(
      userId: 0, // Will be set by the caller
      amount: amount,
      category: category,
      date: date,
      notes: description,
    ));
  }

  /// Parse CSV rows
  static List<Expense> _parseCsvRows(List<List<dynamic>> rows) {
    final expenses = <Expense>[];
    
    if (rows.isEmpty) return [];
    
    // Find header row
    int headerIndex = -1;
    List<String> headers = [];
    
    for (int i = 0; i < rows.length; i++) {
      final rowStr = rows[i].map((e) => e.toString().toLowerCase().trim()).toList();
      if (rowStr.contains('date') || rowStr.contains('transaction date') || rowStr.contains('dt')) {
        headerIndex = i;
        headers = rowStr;
        break;
      }
    }
    
    if (headerIndex == -1) return [];
    
    // Detect format
    String format = 'generic';
    if (headers.contains('phonepe') || 
        (headers.any((h) => h.contains('transaction id')) && headers.any((h) => h.contains('provider reference id')))) {
      format = 'phonepe';
    } else if (headers.contains('google pay') || 
        (headers.any((h) => h.contains('transaction id')) && headers.contains('status') && headers.contains('amount'))) {
      format = 'gpay';
    } else if (headers.any((h) => h.contains('wallet txn id')) || 
        (headers.contains('debit') && headers.contains('credit') && headers.any((h) => h.contains('activity')))) {
      format = 'paytm';
    }
    
    print('[StatementParser] Detected CSV Format: $format');
    
    // Parse data rows
    for (int i = headerIndex + 1; i < rows.length; i++) {
      final row = rows[i].map((e) => e.toString()).toList();
      if (row.isEmpty || (row.length == 1 && row[0].isEmpty)) continue;
      
      try {
        DateTime? date;
        double amount = 0.0;
        String description = 'Expense';
        bool isDebit = false;
        
        if (format == 'phonepe') {
          final dateIdx = headers.indexWhere((h) => h.contains('date'));
          final amountIdx = headers.indexWhere((h) => h.contains('amount'));
          final typeIdx = headers.indexWhere((h) => h.contains('type') || h.contains('cr/dr'));
          final descIdx = headers.indexWhere((h) => h.contains('description') || h.contains('remarks') || h.contains('note'));
          final statusIdx = headers.indexWhere((h) => h.contains('status'));
          
          if (dateIdx != -1 && dateIdx < row.length) date = _parseDate(row[dateIdx]);
          if (statusIdx != -1 && statusIdx < row.length) {
            final status = row[statusIdx].toLowerCase();
            if (!status.contains('success') && !status.contains('completed')) continue;
          }
          if (amountIdx != -1 && amountIdx < row.length) {
            amount = double.tryParse(row[amountIdx].replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
          }
          if (typeIdx != -1 && typeIdx < row.length) {
            final type = row[typeIdx].toLowerCase();
            if (type.contains('debit') || type.contains('dr')) isDebit = true;
          } else {
            if (amount > 0) isDebit = true;
          }
          if (descIdx != -1 && descIdx < row.length) description = row[descIdx];
          
        } else if (format == 'gpay') {
          final dateIdx = headers.indexWhere((h) => h.contains('date'));
          final amountIdx = headers.indexWhere((h) => h.contains('amount'));
          final descIdx = headers.indexWhere((h) => h.contains('description') || h.contains('title'));
          final statusIdx = headers.indexWhere((h) => h.contains('status'));
          
          if (dateIdx != -1 && dateIdx < row.length) date = _parseDate(row[dateIdx]);
          if (statusIdx != -1 && statusIdx < row.length) {
            final status = row[statusIdx].toLowerCase();
            if (!status.contains('success') && !status.contains('completed')) continue;
          }
          if (amountIdx != -1 && amountIdx < row.length) {
            String val = row[amountIdx];
            if (val.contains('-')) isDebit = true;
            val = val.replaceAll(RegExp(r'[^0-9.]'), '');
            amount = double.tryParse(val) ?? 0.0;
          }
          if (descIdx != -1 && descIdx < row.length) {
            description = row[descIdx];
            if (description.toLowerCase().startsWith('sent to') || 
                description.toLowerCase().startsWith('paid to')) {
              isDebit = true;
            }
          }
          
        } else if (format == 'paytm') {
          final dateIdx = headers.indexWhere((h) => h.contains('date'));
          final debitIdx = headers.indexWhere((h) => h.contains('debit'));
          final descIdx = headers.indexWhere((h) => h.contains('source') || h.contains('destination') || h.contains('activity'));
          final statusIdx = headers.indexWhere((h) => h.contains('status'));
          
          if (dateIdx != -1 && dateIdx < row.length) date = _parseDate(row[dateIdx]);
          if (statusIdx != -1 && statusIdx < row.length) {
            final status = row[statusIdx].toLowerCase();
            if (!status.contains('success') && !status.contains('completed')) continue;
          }
          if (debitIdx != -1 && debitIdx < row.length && row[debitIdx].isNotEmpty) {
            amount = double.tryParse(row[debitIdx].replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
            if (amount > 0) isDebit = true;
          }
          if (descIdx != -1 && descIdx < row.length) description = row[descIdx];
          
        } else {
          // Generic format
          int dateIdx = -1, amountIdx = -1, debitIdx = -1, descIdx = -1, typeIdx = -1;
          
          for (int j = 0; j < headers.length; j++) {
            final h = headers[j];
            if (h.contains('date') || h == 'dt') dateIdx = j;
            else if (h.contains('debit') || h.contains('withdrawal')) debitIdx = j;
            else if (h.contains('amount')) amountIdx = j;
            else if (h.contains('desc') || h.contains('particular') || h.contains('narration')) descIdx = j;
            else if (h.contains('type') || h.contains('dr/cr')) typeIdx = j;
          }
          
          if (dateIdx != -1 && dateIdx < row.length) date = _parseDate(row[dateIdx]);
          
          if (date != null) {
            if (debitIdx != -1 && debitIdx < row.length && row[debitIdx].isNotEmpty) {
              amount = double.tryParse(row[debitIdx].replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
              if (amount > 0) isDebit = true;
            }
            
            if (!isDebit && amountIdx != -1 && amountIdx < row.length) {
              amount = double.tryParse(row[amountIdx].replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
              if (typeIdx != -1 && typeIdx < row.length) {
                final type = row[typeIdx].toLowerCase();
                if (type.contains('dr') || type.contains('debit')) isDebit = true;
              } else {
                isDebit = true;
              }
            }
            
            if (descIdx != -1 && descIdx < row.length) description = row[descIdx];
          }
        }
        
        if (date != null && amount > 0 && isDebit) {
          description = description.replaceAll('Paid to ', '').trim();
          expenses.add(Expense(
            userId: 0, // Will be set by the caller
            amount: amount,
            category: 'Other',
            date: date,
            notes: description.trim(),
          ));
        }
      } catch (e) {
        print('Error parsing CSV row $i: $e');
      }
    }
    
    return expenses;
  }

  /// Parse date string
  static DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    
    dateStr = dateStr.trim();
    
    // Handle date with time (e.g., "17/07/2024 10:30")
    if (dateStr.contains(' ') && dateStr.contains('/')) {
      dateStr = dateStr.split(' ')[0];
    }
    
    // Replace dots and slashes with dashes
    dateStr = dateStr.replaceAll(RegExp(r'[./]'), '-');
    
    // Try standard formats
    try {
      final d = DateTime.parse(dateStr);
      if (dateStr.contains('-') && dateStr.length >= 10) return d;
    } catch (_) {}
    
    // Try "DD MMM YYYY" or "D MMM, YYYY"
    final match1 = RegExp(r'^(\d{1,2})\s+([A-Za-z]+),?\s+(\d{4})$').firstMatch(dateStr);
    if (match1 != null) {
      final day = int.parse(match1.group(1)!);
      final month = _monthNameToNumber(match1.group(2)!);
      final year = int.parse(match1.group(3)!);
      if (month != null) return DateTime(year, month, day);
    }
    
    // Try "MMM DD, YYYY"
    final match2 = RegExp(r'^([A-Za-z]+)\s+(\d{1,2}),?\s+(\d{4})$').firstMatch(dateStr);
    if (match2 != null) {
      final month = _monthNameToNumber(match2.group(1)!);
      final day = int.parse(match2.group(2)!);
      final year = int.parse(match2.group(3)!);
      if (month != null) return DateTime(year, month, day);
    }
    
    // Try "DD MMM"
    final match3 = RegExp(r'^(\d{1,2})\s+([A-Za-z]+)$').firstMatch(dateStr);
    if (match3 != null) {
      final day = int.parse(match3.group(1)!);
      final month = _monthNameToNumber(match3.group(2)!);
      final year = DateTime.now().year;
      if (month != null) return DateTime(year, month, day);
    }
    
    // Try DD-MM-YYYY or MM-DD-YYYY
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      int p1 = int.parse(parts[0]);
      int p2 = int.parse(parts[1]);
      int p3 = int.parse(parts[2]);
      
      if (p3 < 100) p3 += 2000;
      
      // Guess format
      if (p1 > 12) return DateTime(p3, p2, p1); // DD-MM-YYYY
      if (p2 > 12) return DateTime(p3, p1, p2); // MM-DD-YYYY
      
      // Ambiguous, default to DD-MM-YYYY (common in India)
      return DateTime(p3, p2, p1);
    }
    
    return null;
  }

  /// Convert month name to number
  static int? _monthNameToNumber(String monthStr) {
    final months = {
      'jan': 1, 'january': 1,
      'feb': 2, 'february': 2,
      'mar': 3, 'march': 3,
      'apr': 4, 'april': 4,
      'may': 5,
      'jun': 6, 'june': 6,
      'jul': 7, 'july': 7,
      'aug': 8, 'august': 8,
      'sep': 9, 'september': 9,
      'oct': 10, 'october': 10,
      'nov': 11, 'november': 11,
      'dec': 12, 'december': 12,
    };
    
    return months[monthStr.toLowerCase().substring(0, 3)];
  }
}
