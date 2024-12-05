import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:toepwar/screens/addtransaction_screen.dart';
import 'transactionhistory_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String token;

  DashboardScreen({required this.token});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> dashboardData;
  late Future<List<dynamic>> transactionHistory;

  Future<Map<String, dynamic>> fetchDashboard() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.9:800/dashboard'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load dashboard');
    }
  }

  Future<List<dynamic>> fetchTransactionHistory() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.9:800/transactions'), // Endpoint for transaction history
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load transaction history');
    }
  }

  @override
  void initState() {
    super.initState();
    dashboardData = fetchDashboard();
    transactionHistory = fetchTransactionHistory();
  }

  void refreshData() {
    setState(() {
      dashboardData = fetchDashboard();
      transactionHistory = fetchTransactionHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final data = snapshot.data!;
            return Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Income and Expense
                  Text('Total Income: \$${data['income']}',
                      style: TextStyle(fontSize: 18)),
                  Text('Total Expense: \$${data['expense']}',
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 20),

                  // Add Transaction Button
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddTransactionScreen(token: widget.token),
                        ),
                      );
                      if (result == true) {
                        refreshData(); // Refresh dashboard and history on return
                      }
                    },
                    child: Text('Add Transactions'),
                  ),

                  SizedBox(height: 20),

                  // Transaction History Section
                  Text(
                    'Recent Transactions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  FutureBuilder<List<dynamic>>(
                    future: transactionHistory,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        final transactions = snapshot.data!;
                        if (transactions.isEmpty) {
                          return Text('No transactions yet.');
                        } else {
                          // Display only the last 3 transactions
                          final recentTransactions =
                          transactions.take(3).toList();
                          return Column(
                            children: [
                              ...recentTransactions.map((transaction) {
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
                              }).toList(),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TransactionHistoryScreen(
                                            token: widget.token,
                                          ),
                                    ),
                                  );
                                },
                                child: Text('See More'),
                              ),
                            ],
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}