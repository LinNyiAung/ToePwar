import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import '../utils/api_constants.dart';

class TransactionController {
  final String token;

  TransactionController({required this.token});

  Future<List<Transaction>> getTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/gettransactions'),
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
        Uri.parse(
            '${ApiConstants.baseUrl}/addtransactions'), // Updated endpoint
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Transaction.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add transaction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  Future<Transaction> editTransaction({
    required String id,
    required String type,
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
            '${ApiConstants.baseUrl}/edittransactions/$id'), // Updated endpoint
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'type': type,
          'amount': amount,
          'category': category,
          'date': date.toIso8601String(),
        }),
      );

      print('Edit URL: ${ApiConstants.baseUrl}/edittransactions/$id');
      print('Edit Request Body: ${json.encode({
            'type': type,
            'amount': amount,
            'category': category,
            'date': date.toIso8601String(),
          })}');

      if (response.statusCode == 200) {
        print('Response: ${response.statusCode} - ${response.body}');

        return Transaction.fromJson(json.decode(response.body));
      } else {
        print('Response: ${response.statusCode} - ${response.body}');

        throw Exception(
            'Failed to update transaction: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  // Add confirmation before delete
  Future<bool> confirmDelete(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirm Delete'),
              content:
                  Text('Are you sure you want to delete this transaction?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '${ApiConstants.baseUrl}/deletetransactions/$id'), // Updated endpoint
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Delete URL: ${ApiConstants.baseUrl}/deletetransactions/$id');

      if (response.statusCode != 200) {
        print('Response: ${response.statusCode} - ${response.body}');

        throw Exception('Failed to delete transaction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }
}
