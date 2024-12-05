import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:toepwar/screens/addtransaction_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String token;

  DashboardScreen({required this.token});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> dashboardData;

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

  @override
  void initState() {
    super.initState();
    dashboardData = fetchDashboard();
  }

  void refreshDashboard() {
    setState(() {
      dashboardData = fetchDashboard();
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
                  Text('Total Income: \$${data['income']}',
                      style: TextStyle(fontSize: 18)),
                  Text('Total Expense: \$${data['expense']}',
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTransactionScreen(token: widget.token),
                        ),
                      );
                      if (result == true) {
                        refreshDashboard(); // Refresh data after returning
                      }
                    },
                    child: Text('Add Transactions'),
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
