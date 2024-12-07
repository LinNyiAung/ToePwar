import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import '../utils/api_constants.dart';

class TransactionController {
  final String token;

  TransactionController({required this.token});

  Future<List<Transaction>> getTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/transactions'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> transactionsJson = json.decode(response.body);
        return transactionsJson
            .map((json) => Transaction.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  Future<Transaction> addTransaction({
    required String type,
    required double amount,
    required String category,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/transaction'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'type': type,
          'amount': amount,
          'category': category,
          'date': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return Transaction.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add transaction');
      }
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/transaction/$transactionId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete transaction');
      }
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }
}
