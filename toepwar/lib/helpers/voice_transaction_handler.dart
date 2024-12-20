import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';
import '../controllers/transaction_controller.dart';
import '../utils/api_constants.dart';

class VoiceTransactionHandler {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TransactionController _transactionController;

  VoiceTransactionHandler({required TransactionController transactionController})
      : _transactionController = transactionController;

  Future<bool> initialize() async {
    return await _speech.initialize();
  }

  Future<Map<String, dynamic>?> processVoiceInput(BuildContext context) async {
    if (!await _speech.initialize()) {
      throw Exception('Speech recognition not available');
    }

    String recognizedText = '';

    await _speech.listen(
      onResult: (result) {
        recognizedText = result.recognizedWords;
      },
      cancelOnError: true,
    );

    // Wait for speech input to complete
    await Future.delayed(const Duration(seconds: 5));
    await _speech.stop();

    if (recognizedText.isEmpty) {
      return null;
    }

    // Parse the voice input
    return parseVoiceInput(recognizedText);
  }

  Map<String, dynamic>? parseVoiceInput(String text) {
    text = text.toLowerCase();

    // Extract amount
    RegExp amountRegex = RegExp(r'\d+(\.\d{1,2})?');
    final amount = amountRegex.firstMatch(text)?.group(0);

    // Determine transaction type
    String type = 'expense'; // Default to expense
    if (text.contains('income') ||
        text.contains('earned') ||
        text.contains('received') ||
        text.contains('salary')) {
      type = 'income';
    }

    // Find matching category
    String? category;
    final categories = ApiConstants.nestedTransactionCategories[type]!;

    for (var mainCategory in categories.keys) {
      for (var subCategory in categories[mainCategory]!) {
        if (text.contains(subCategory.toLowerCase())) {
          category = subCategory;
          break;
        }
      }
      if (category != null) break;
    }

    // Parse date
    DateTime? date = _parseDate(text);

    if (amount == null || category == null) {
      return null;
    }

    return {
      'type': type,
      'amount': double.parse(amount),
      'category': category,
      'date': date, // Will be null if no date is found
    };
  }

  DateTime? _parseDate(String text) {
    // Current date for reference
    DateTime now = DateTime.now();

    // Try to parse various date formats and expressions

    // Check for "today", "yesterday", "tomorrow"
    if (text.contains('today')) {
      return DateTime(now.year, now.month, now.day);
    }
    if (text.contains('yesterday')) {
      return DateTime(now.year, now.month, now.day - 1);
    }

    // Check for relative days (e.g., "3 days ago", "last week")
    RegExp daysAgoRegex = RegExp(r'(\d+)\s*days?\s*ago');
    var daysAgoMatch = daysAgoRegex.firstMatch(text);
    if (daysAgoMatch != null) {
      int daysAgo = int.parse(daysAgoMatch.group(1)!);
      return DateTime(now.year, now.month, now.day - daysAgo);
    }

    // Check for month and day (e.g., "January 15", "Jan 15")
    final months = {
      'january': 1, 'jan': 1,
      'february': 2, 'feb': 2,
      'march': 3, 'mar': 3,
      'april': 4, 'apr': 4,
      'may': 5,
      'june': 6, 'jun': 6,
      'july': 7, 'jul': 7,
      'august': 8, 'aug': 8,
      'september': 9, 'sep': 9,
      'october': 10, 'oct': 10,
      'november': 11, 'nov': 11,
      'december': 12, 'dec': 12
    };

    for (var month in months.keys) {
      if (text.contains(month)) {
        RegExp dayRegex = RegExp('$month\\s+(\\d+)', caseSensitive: false);
        var match = dayRegex.firstMatch(text);
        if (match != null) {
          int day = int.parse(match.group(1)!);
          int monthNumber = months[month]!;
          // If the date is in the future, assume it's from last year
          DateTime date = DateTime(now.year, monthNumber, day);
          if (date.isAfter(now)) {
            date = DateTime(now.year - 1, monthNumber, day);
          }
          return date;
        }
      }
    }

    // Check for MM/DD format
    RegExp dateRegex = RegExp(r'(\d{1,2})/(\d{1,2})');
    var dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      int month = int.parse(dateMatch.group(1)!);
      int day = int.parse(dateMatch.group(2)!);
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        // If the date is in the future, assume it's from last year
        DateTime date = DateTime(now.year, month, day);
        if (date.isAfter(now)) {
          date = DateTime(now.year - 1, month, day);
        }
        return date;
      }
    }

    return null;
  }
}