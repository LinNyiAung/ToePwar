import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddTransactionScreen extends StatelessWidget {
  final String token;

  AddTransactionScreen({required this.token});

  final TextEditingController amountController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final List<String> transactionTypes = ['income', 'expense'];
  String selectedType = 'income';

  Future<void> addTransaction(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.9:800/transaction'), // Correct URL
        headers: {
          'Authorization': 'Bearer $token', // Token for user authentication
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'type': selectedType,
          'amount': double.parse(amountController.text), // Parse to float
          'category': categoryController.text,
          'date': DateTime.now().toIso8601String(), // ISO 8601 format
        }),
      );

      if (response.statusCode == 200) {
        print('Transaction added successfully');
        Navigator.pop(context, true); // Go back to the dashboard and pass a flag
      } else {
        print('Failed to add transaction: ${response.statusCode}, ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add transaction')),
        );
      }
    } catch (e) {
      print('Error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Transaction')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedType,
              items: transactionTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                if (value != null) selectedType = value;
              },
            ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: categoryController,
              decoration: InputDecoration(labelText: 'Category'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => addTransaction(context),
              child: Text('Add Transaction'),
            ),

          ],
        ),
      ),
    );
  }
}
