import 'package:flutter/material.dart';
import '../../controllers/transaction_controller.dart';
import '../../utils/api_constants.dart';

class AddTransactionView extends StatefulWidget {
  final String token;
  final VoidCallback onTransactionChanged;

  AddTransactionView({required this.token, required this.onTransactionChanged,});

  @override
  _AddTransactionViewState createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<AddTransactionView> {
  late final TransactionController _transactionController;
  final _amountController = TextEditingController();
  String _selectedType = 'income';
  String? _selectedMainCategory;
  String? _selectedSubCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _transactionController = TransactionController(token: widget.token);
    _selectedMainCategory =
        ApiConstants.nestedTransactionCategories[_selectedType]!.keys.first;
    _selectedSubCategory =
        ApiConstants.nestedTransactionCategories[_selectedType]![_selectedMainCategory]!.first;
  }

  Future<void> _addTransaction() async {
    if (_amountController.text.isEmpty ||
        _selectedSubCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _transactionController.addTransaction(
        type: _selectedType,
        amount: double.parse(_amountController.text),
        category: _selectedSubCategory!, // Store the subcategory
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


  @override
  Widget build(BuildContext context) {
    final categoriesMap =
    ApiConstants.nestedTransactionCategories[_selectedType]!;

    return Scaffold(
      appBar: AppBar(title: Text('Add Transaction')),
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
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _addTransaction,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
