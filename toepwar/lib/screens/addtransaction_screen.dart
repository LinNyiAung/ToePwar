import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddTransactionScreen extends StatefulWidget {
  final String token;

  AddTransactionScreen({required this.token});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController amountController = TextEditingController();
  final List<String> transactionTypes = ['income', 'expense'];
  final Map<String, List<String>> categories = {
    'income': ['Salary', 'Business', 'Investment', 'Gift', 'Other'],
    'expense': ['Shopping', 'Food', 'Transportation', 'Bills', 'Other'],
  };
  String selectedType = 'income';
  String? selectedCategory;

  Future<void> addTransaction(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.9:800/transaction'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'type': selectedType,
          'amount': double.parse(amountController.text),
          'category': selectedCategory,
          'date': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        print('Transaction added successfully');
        Navigator.pop(context, true); // Return to the dashboard with success flag
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
            // Transaction Type Dropdown
            DropdownButtonFormField<String>(
              value: selectedType,
              items: transactionTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedType = value;
                    selectedCategory = null; // Reset category when type changes
                  });
                }
              },
              decoration: InputDecoration(labelText: 'Transaction Type'),
            ),

            // Amount Text Field
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categories[selectedType]!.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
              decoration: InputDecoration(labelText: 'Category'),
            ),

            SizedBox(height: 20),

            // Add Transaction Button
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
