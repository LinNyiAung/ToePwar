import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TransactionHistoryScreen extends StatelessWidget {
  final String token;

  TransactionHistoryScreen({required this.token});

  Future<List<dynamic>> fetchTransactionHistory() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.9:800/transactions'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load transaction history');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaction History')),
      body: FutureBuilder<List<dynamic>>(
        future: fetchTransactionHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final transactions = snapshot.data!;
            if (transactions.isEmpty) {
              return Center(child: Text('No transactions yet.'));
            } else {
              return ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return ListTile(
                    leading: Icon(
                      transaction['type'] == 'income'
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: transaction['type'] == 'income'
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: Text(transaction['category']),
                    subtitle: Text(
                        '${transaction['date']} - \$${transaction['amount']}'),
                  );
                },
              );
            }
          }
        },
      ),
    );
  }
}
