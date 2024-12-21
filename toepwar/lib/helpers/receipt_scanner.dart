import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class ReceiptScanner {
  final textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();

  Future<double?> scanReceipt(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return null;

      final inputImage = InputImage.fromFile(File(image.path));
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      return extractTotalAmount(recognizedText.text);
    } catch (e) {
      print('Error scanning receipt: $e');
      return null;
    }
  }

  double? extractTotalAmount(String text) {
    final lines = text.split('\n');

    // Pattern for matching amounts with optional thousands separator
    RegExp amountPattern = RegExp(r'[0-9,]+\.?[0-9]*');

    // Keywords that indicate total amount, ordered by priority
    final totalKeywords = [
      'total:(inclusive tax)',
      'total : (inclusive tax)',
      'total:(inclusive',
      'total : inclusive',
      'total',
      'grand total',
      'amount',
      'final amount',
    ];

    // First pass: Look for total keywords and extract amount from the same line
    for (String line in lines) {
      String lowercaseLine = line.toLowerCase().trim();

      // Skip lines with "subtotal", "commercial tax", or standalone "tax"
      if (lowercaseLine.contains('subtotal') ||
          lowercaseLine.contains('commercial tax') ||
          (lowercaseLine.contains('tax') && !lowercaseLine.contains('inclusive'))) {
        continue;
      }

      // Check for total keywords
      for (String keyword in totalKeywords) {
        if (lowercaseLine.contains(keyword)) {
          // Split the line by common separators
          List<String> parts = line.split(RegExp(r'[:\s]+'));

          // Look for amounts in the parts after the keyword
          int keywordIndex = -1;
          for (int i = 0; i < parts.length; i++) {
            if (parts[i].toLowerCase().contains(keyword)) {
              keywordIndex = i;
              break;
            }
          }

          if (keywordIndex != -1) {
            // Check parts after the keyword
            for (int i = keywordIndex + 1; i < parts.length; i++) {
              if (amountPattern.hasMatch(parts[i])) {
                String amount = amountPattern.firstMatch(parts[i])!.group(0)!.replaceAll(',', '');
                double? parsedAmount = double.tryParse(amount);
                if (parsedAmount != null) {
                  return parsedAmount;
                }
              }
            }
          } else {
            // If keyword not found in parts (might be due to different formatting),
            // extract the last number from the line
            final matches = amountPattern.allMatches(line);
            if (matches.isNotEmpty) {
              String amount = matches.last.group(0)!.replaceAll(',', '');
              double? parsedAmount = double.tryParse(amount);
              if (parsedAmount != null) {
                return parsedAmount;
              }
            }
          }
        }
      }
    }

    // Second pass: Look for patterns like "Total" followed by amount on the next line
    for (int i = 0; i < lines.length - 1; i++) {
      String currentLine = lines[i].toLowerCase().trim();
      String nextLine = lines[i + 1].trim();

      for (String keyword in totalKeywords) {
        if (currentLine.contains(keyword) &&
            !currentLine.contains(RegExp(r'[0-9]'))) {
          // If current line only contains the keyword, check next line for amount
          final matches = amountPattern.allMatches(nextLine);
          if (matches.isNotEmpty) {
            String amount = matches.first.group(0)!.replaceAll(',', '');
            double? parsedAmount = double.tryParse(amount);
            if (parsedAmount != null) {
              return parsedAmount;
            }
          }
        }
      }
    }

    // Fallback: Look for the last valid amount before any change amount
    for (int i = lines.length - 1; i >= 0; i--) {
      String line = lines[i].toLowerCase();

      // Skip change amount lines
      if (line.contains('changed:') || line.contains('change')) {
        continue;
      }

      final matches = amountPattern.allMatches(line);
      if (matches.isNotEmpty) {
        String amount = matches.first.group(0)!.replaceAll(',', '');
        double? parsedAmount = double.tryParse(amount);
        if (parsedAmount != null) {
          return parsedAmount;
        }
      }
    }

    return null;
  }
}