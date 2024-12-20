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

    if (amount == null || category == null) {
      return null;
    }

    return {
      'type': type,
      'amount': double.parse(amount),
      'category': category,
    };
  }
}