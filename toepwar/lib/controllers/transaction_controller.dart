import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../helpers/notification_service.dart';
import '../models/notification_model.dart';
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
        final responseData = json.decode(response.body);

        // Handle multiple notifications if present
        if (responseData['notifications'] != null) {
          for (var notificationData in responseData['notifications']) {
            final notification = AppNotification.fromJson(notificationData);

            // Show appropriate notification based on type
            if (notification.type == NotificationType.expenseAlert) {
              await NotificationService.instance.showExpenseAlert(notification);
            } else if (notification.type == NotificationType.goalProgress) {
              await NotificationService.instance.showGoalProgressNotification(notification);
            }
          }
        }

        // Return the transaction data
        return Transaction.fromJson(responseData['transaction']);
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
