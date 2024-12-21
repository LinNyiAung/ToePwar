import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class ReceiptScanner {
  final textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();

  Future<double?> scanReceipt(ImageSource source) async {
    try {
      // Pick image
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return null;

      // Process image
      final inputImage = InputImage.fromFile(File(image.path));
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      // Extract total amount
      return extractTotalAmount(recognizedText.text);
    } catch (e) {
      print('Error scanning receipt: $e');
      return null;
    }
  }

  double? extractTotalAmount(String text) {
    // Convert text to lowercase and split into lines
    final lines = text.toLowerCase().split('\n');

    // Look for lines containing total
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('total')) {
        // Extract numbers from this line
        RegExp regExp = RegExp(r'[0-9,]+\.?[0-9]*');
        final matches = regExp.allMatches(lines[i]);

        if (matches.isNotEmpty) {
          // Get the last number in the line (usually the total)
          String amount = matches.last.group(0)!.replaceAll(',', '');
          return double.tryParse(amount);
        }
      }
    }

    // If no total found, try to get the last number in the receipt
    RegExp regExp = RegExp(r'[0-9,]+\.?[0-9]*');
    final allMatches = regExp.allMatches(text);
    if (allMatches.isNotEmpty) {
      String amount = allMatches.last.group(0)!.replaceAll(',', '');
      return double.tryParse(amount);
    }

    return null;
  }
}