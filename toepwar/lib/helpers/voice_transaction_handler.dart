import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';
import '../controllers/transaction_controller.dart';
import '../utils/api_constants.dart';

class VoiceTransactionHandler {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TransactionController _transactionController;

  // Number word mappings
  static const Map<String, int> _numberWords = {
    'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4,
    'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9,
    'ten': 10, 'eleven': 11, 'twelve': 12, 'thirteen': 13,
    'fourteen': 14, 'fifteen': 15, 'sixteen': 16,
    'seventeen': 17, 'eighteen': 18, 'nineteen': 19,
    'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50,
    'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
  };

  static const Map<String, int> _multipliers = {
    'hundred': 100,
    'thousand': 1000,
    'k': 1000,
  };

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

    await Future.delayed(const Duration(seconds: 5));
    await _speech.stop();

    if (recognizedText.isEmpty) {
      return null;
    }

    return parseVoiceInput(recognizedText);
  }

  double? _parseSpokenAmount(String text) {
    text = text.toLowerCase();
    List<String> words = text.split(' ');

    // First try to find direct number patterns (e.g., "1000" or "1,000")
    RegExp numericPattern = RegExp(r'\b\d+(?:,\d{3})*(?:\.\d{1,2})?\b');
    var numericMatch = numericPattern.firstMatch(text);
    if (numericMatch != null) {
      String numStr = numericMatch.group(0)!.replaceAll(',', '');
      return double.tryParse(numStr);
    }

    // Process spoken numbers
    int currentNumber = 0;
    int tempNumber = 0;
    int? result;

    for (int i = 0; i < words.length; i++) {
      String word = words[i].toLowerCase();

      // Check for number words
      if (_numberWords.containsKey(word)) {
        tempNumber += _numberWords[word]!;
      }
      // Check for multipliers
      else if (_multipliers.containsKey(word)) {
        // Handle cases like "one thousand"
        if (tempNumber == 0) tempNumber = 1;

        if (word == 'hundred') {
          tempNumber *= 100;
        } else if (word == 'thousand' || word == 'k') {
          tempNumber *= 1000;
          currentNumber += tempNumber;
          tempNumber = 0;
        }
      }
      // Handle compound numbers (e.g., "twenty one")
      else if (word == 'and') {
        continue;
      }
      // If we hit a non-number word, process what we have
      else {
        if (tempNumber > 0) {
          currentNumber += tempNumber;
          tempNumber = 0;
        }
      }
    }

    // Add any remaining number
    if (tempNumber > 0) {
      currentNumber += tempNumber;
    }

    // If we found a number, return it
    if (currentNumber > 0) {
      return currentNumber.toDouble();
    }

    return null;
  }

  Map<String, dynamic>? parseVoiceInput(String text) {
    text = text.toLowerCase();

    // Extract amount using the new parser
    double? amount = _parseSpokenAmount(text);

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
      'amount': amount,
      'category': category,
      'date': date,
    };
  }

  DateTime? _parseDate(String text) {
    // [Existing date parsing code remains the same]
    DateTime now = DateTime.now();

    if (text.contains('today')) {
      return DateTime(now.year, now.month, now.day);
    }
    if (text.contains('yesterday')) {
      return DateTime(now.year, now.month, now.day - 1);
    }

    RegExp daysAgoRegex = RegExp(r'(\d+)\s*days?\s*ago');
    var daysAgoMatch = daysAgoRegex.firstMatch(text);
    if (daysAgoMatch != null) {
      int daysAgo = int.parse(daysAgoMatch.group(1)!);
      return DateTime(now.year, now.month, now.day - daysAgo);
    }

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
          DateTime date = DateTime(now.year, monthNumber, day);
          if (date.isAfter(now)) {
            date = DateTime(now.year - 1, monthNumber, day);
          }
          return date;
        }
      }
    }

    RegExp dateRegex = RegExp(r'(\d{1,2})/(\d{1,2})');
    var dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      int month = int.parse(dateMatch.group(1)!);
      int day = int.parse(dateMatch.group(2)!);
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
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