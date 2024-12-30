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
  DateTime? _lastSyncTime;

  TransactionController({required this.token});

  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<List<TransactionModel>> initializeData() async {
    final localTransactions = await dbHelper.getAllTransactions();

    if (await hasInternetConnection()) {
      try {
        await syncWithServer();
      } catch (e) {
        print('Failed to sync with server: $e');
      }
    }

    return await dbHelper.getAllTransactions();
  }

  Future<List<TransactionModel>> getTransactions() async {
    return await dbHelper.getAllTransactions();
  }

  Future<void> syncWithServer() async {
    if (!await hasInternetConnection()) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/gettransactions'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> transactionsJson = json.decode(response.body);
        final serverTransactions = transactionsJson
            .map((json) => TransactionModel.fromJson(json))
            .toList();

        // Sort server transactions by date (newest first) before saving
        serverTransactions.sort((a, b) => b.date.compareTo(a.date));

        await dbHelper.clearAllTransactions();
        for (var transaction in serverTransactions) {
          await dbHelper.insertTransaction(transaction);
        }

        _lastSyncTime = DateTime.now();
      }
    } catch (e) {
      print('Error during sync: $e');
      throw Exception('Failed to sync with server');
    }
  }

  Future<TransactionModel> addTransaction({
    required String type,
    required double amount,
    required String category,
  }) async {
    late TransactionModel transaction;

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
          transaction = TransactionModel.fromJson(json.decode(response.body));
        } else {
          throw Exception('Server error');
        }
      } else {
        transaction = TransactionModel(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          type: type,
          amount: amount,
          category: category,
          date: DateTime.now(),
        );
      }

      await dbHelper.insertTransaction(transaction);
      return transaction;
    } catch (e) {
      print('Error in addTransaction: $e');
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
    late TransactionModel transaction;

    try {
      if (await hasInternetConnection()) {
        // Try online first
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
          transaction = TransactionModel.fromJson(json.decode(response.body));
          await syncWithServer(); // Full sync after successful edit
        } else {
          throw Exception('Server error');
        }
      } else {
        // Offline fallback
        transaction = TransactionModel(
          id: id,
          type: type,
          amount: amount,
          category: category,
          date: date,
        );
      }

      // Update local DB
      await dbHelper.updateTransaction(transaction);
      return transaction;
    } catch (e) {
      print('Error in editTransaction: $e');
      throw Exception('Failed to update transaction: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      // Delete from local DB first
      await dbHelper.deleteTransaction(id);

      if (await hasInternetConnection()) {
        // Then try to delete from server
        final response = await http.delete(
          Uri.parse('${ApiConstants.baseUrl}/deletetransactions/$id'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          await syncWithServer(); // Full sync after successful delete
        } else {
          // If server delete fails, restore the local deletion
          throw Exception('Server error');
        }
      }
    } catch (e) {
      print('Error in deleteTransaction: $e');
      throw Exception('Failed to delete transaction: $e');
    }
  }

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