import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../../utils/api_constants.dart';

class EditTransactionView extends StatefulWidget {
  final String token;
  final Transaction transaction;
  final VoidCallback onTransactionChanged;

  EditTransactionView({
    required this.token,
    required this.transaction,
    required this.onTransactionChanged,
  });

  @override
  _EditTransactionViewState createState() => _EditTransactionViewState();
}

class _EditTransactionViewState extends State<EditTransactionView> {
  late final TransactionController _transactionController;
  late final TextEditingController _amountController;
  late String _selectedType;
  String? _selectedMainCategory;
  String? _selectedSubCategory;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _transactionController = TransactionController(token: widget.token);
    _amountController = TextEditingController(
      text: widget.transaction.amount.toString(),
    );

    _selectedType = widget.transaction.type;
    _selectedDate = widget.transaction.date;

    // Determine main and sub categories
    final categoriesMap =
    ApiConstants.nestedTransactionCategories[_selectedType]!;

    // Find the main category that contains the current category
    _selectedMainCategory = categoriesMap.keys.firstWhere(
            (mainCategory) => categoriesMap[mainCategory]!.contains(widget.transaction.category),
        orElse: () => categoriesMap.keys.first
    );
    _selectedSubCategory = widget.transaction.category;
  }

  Future<void> _updateTransaction() async {
    if (_amountController.text.isEmpty || _selectedSubCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _transactionController.editTransaction(
        id: widget.transaction.id,
        type: _selectedType,
        amount: double.parse(_amountController.text),
        category: _selectedSubCategory!, // Store the subcategory
        date: _selectedDate,
      );
      widget.onTransactionChanged();
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesMap =
    ApiConstants.nestedTransactionCategories[_selectedType]!;

    return Scaffold(
      appBar: AppBar(title: Text('Edit Transaction')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Transaction Type',
                border: OutlineInputBorder(),
              ),
              items: ['income', 'expense'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                  // Reset categories when type changes
                  _selectedMainCategory =
                      ApiConstants.nestedTransactionCategories[_selectedType]!.keys.first;
                  _selectedSubCategory =
                      ApiConstants.nestedTransactionCategories[_selectedType]![_selectedMainCategory]!.first;
                });
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMainCategory,
              decoration: InputDecoration(
                labelText: 'Main Category',
                border: OutlineInputBorder(),
              ),
              items: categoriesMap.keys.map((mainCategory) {
                return DropdownMenuItem(
                    value: mainCategory,
                    child: Text(mainCategory)
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMainCategory = value;
                  // Reset subcategory to first in the new main category
                  _selectedSubCategory =
                      categoriesMap[_selectedMainCategory]!.first;
                });
              },
            ),
            SizedBox(height: 16),

            // Subcategory Dropdown
            DropdownButtonFormField<String>(
              value: _selectedSubCategory,
              decoration: InputDecoration(
                labelText: 'Subcategory',
                border: OutlineInputBorder(),
              ),
              items: categoriesMap[_selectedMainCategory]!.map((subCategory) {
                return DropdownMenuItem(
                    value: subCategory,
                    child: Text(subCategory)
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubCategory = value;
                });
              },
            ),
            SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  DateFormat('MMM d, yyyy').format(_selectedDate),
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateTransaction,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Update Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}