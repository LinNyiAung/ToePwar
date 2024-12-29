import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../helpers/transaction_db_helper.dart';
import '../models/transaction_model.dart';
import '../utils/api_constants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


class TransactionController {
  final String token;
  final TransactionDbHelper dbHelper = TransactionDbHelper.instance;

  TransactionController({required this.token});

  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<List<TransactionModel>> getTransactions() async {
    try {
      if (await hasInternetConnection()) {
        final response = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/gettransactions'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> transactionsJson = json.decode(response.body);
          final transactions = transactionsJson
              .map((json) => TransactionModel.fromJson(json))
              .toList();

          await dbHelper.clearAllTransactions();
          for (var transaction in transactions) {
            await dbHelper.insertTransaction(transaction);
          }
          return transactions;
        }
      }

      return await dbHelper.getAllTransactions();
    } catch (e) {
      return await dbHelper.getAllTransactions();
    }
  }

  Future<TransactionModel> addTransaction({
    required String type,
    required double amount,
    required String category,
  }) async {
    try {
      if (await hasInternetConnection()) {
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/addtransactions'),
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
          final transaction = TransactionModel.fromJson(json.decode(response.body));
          await dbHelper.insertTransaction(transaction);
          return transaction;
        }
      }
      throw Exception('Failed to add transaction');
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  Future<TransactionModel> editTransaction({
    required String id,
    required String type,
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    try {
      if (await hasInternetConnection()) {
        final response = await http.put(
          Uri.parse('${ApiConstants.baseUrl}/edittransactions/$id'),
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

        if (response.statusCode == 200) {
          final transaction = TransactionModel.fromJson(json.decode(response.body));
          await dbHelper.updateTransaction(transaction);
          return transaction;
        }
      }
      throw Exception('Failed to update transaction');
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      if (await hasInternetConnection()) {
        final response = await http.delete(
          Uri.parse('${ApiConstants.baseUrl}/deletetransactions/$id'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          await dbHelper.deleteTransaction(id);
          return;
        }
      }
      throw Exception('Failed to delete transaction');
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  // Add confirmation before delete
  Future<bool> confirmDelete(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this transaction?'),
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
    ) ?? false;
  }



}
