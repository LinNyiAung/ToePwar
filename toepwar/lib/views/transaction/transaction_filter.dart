import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/transaction_model.dart';
import '../../utils/api_constants.dart';

class TransactionFilter {
  final String? type;
  final String? mainCategory;
  final String? subCategory;
  final DateTimeRange? dateRange;

  TransactionFilter({
    this.type,
    this.mainCategory,
    this.subCategory,
    this.dateRange
  });

  bool apply(TransactionModel transaction) {
    bool matchesFilters = true;

    // Check transaction type
    if (type != null && type!.isNotEmpty && type != 'All') {
      matchesFilters = matchesFilters && transaction.type == type;
    }

    // Check main category if specified
    if (mainCategory != null && mainCategory!.isNotEmpty && mainCategory != 'All') {
      // Find the main category for the transaction's subcategory
      final categoriesMap = ApiConstants.nestedTransactionCategories[transaction.type]!;
      final transactionMainCategory = categoriesMap.keys.firstWhere(
            (main) => categoriesMap[main]!.contains(transaction.category),
        orElse: () => '',
      );
      matchesFilters = matchesFilters && transactionMainCategory == mainCategory;
    }

    // Check subcategory if specified
    if (subCategory != null && subCategory!.isNotEmpty && subCategory != 'All') {
      matchesFilters = matchesFilters && transaction.category == subCategory;
    }

    // Check date range
    if (dateRange != null) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      matchesFilters = matchesFilters &&
          !date.isBefore(dateRange!.start) &&
          !date.isAfter(dateRange!.end);
    }

    return matchesFilters;
  }
}

class TransactionFilterDialog extends StatefulWidget {
  final TransactionFilter? initialFilter;

  const TransactionFilterDialog({this.initialFilter});

  @override
  _TransactionFilterDialogState createState() => _TransactionFilterDialogState();
}

class _TransactionFilterDialogState extends State<TransactionFilterDialog> {
  String? _selectedType;
  String? _selectedMainCategory;
  String? _selectedSubCategory;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // Initialize with existing filter values or defaults
    _selectedType = widget.initialFilter?.type;
    _selectedMainCategory = widget.initialFilter?.mainCategory;
    _selectedSubCategory = widget.initialFilter?.subCategory;
    _selectedDateRange = widget.initialFilter?.dateRange;
  }

  @override
  Widget build(BuildContext context) {
    // Get categories based on selected type (or first type if not selected)
    final categoriesMap = _selectedType != null
        ? ApiConstants.nestedTransactionCategories[_selectedType]!
        : ApiConstants.nestedTransactionCategories['income']!;

    return AlertDialog(
      title: Text('Filter Transactions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Transaction Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(labelText: 'Type'),
              items: [
                DropdownMenuItem(value: null, child: Text('All')),
                ...['income', 'expense'].map((type) =>
                    DropdownMenuItem(value: type, child: Text(type.capitalize()))
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                  // Reset categories when type changes
                  _selectedMainCategory = null;
                  _selectedSubCategory = null;
                });
              },
            ),
            SizedBox(height: 16),

            // Main Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedMainCategory,
              decoration: InputDecoration(labelText: 'Main Category'),
              hint: Text('Select Main Category'),
              items: [
                DropdownMenuItem(value: null, child: Text('All')),
                if (_selectedType != null)
                  ...ApiConstants.nestedTransactionCategories[_selectedType]!.keys
                      .map((mainCategory) =>
                      DropdownMenuItem(
                          value: mainCategory,
                          child: Text(mainCategory)
                      )
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedMainCategory = value;
                  // Reset subcategory when main category changes
                  _selectedSubCategory = null;
                });
              },
            ),
            SizedBox(height: 16),

            // Subcategory Dropdown
            if (_selectedType != null && _selectedMainCategory != null)
              DropdownButtonFormField<String>(
                value: _selectedSubCategory,
                decoration: InputDecoration(labelText: 'Subcategory'),
                hint: Text('Select Subcategory'),
                items: [
                  DropdownMenuItem(value: null, child: Text('All')),
                  ...ApiConstants.nestedTransactionCategories[_selectedType]![_selectedMainCategory]!
                      .map((subCategory) =>
                      DropdownMenuItem(
                          value: subCategory,
                          child: Text(subCategory)
                      )
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSubCategory = value;
                  });
                },
              ),

            // Date Range Selection
            ListTile(
              title: Text('Date Range'),
              subtitle: Text(_selectedDateRange != null
                  ? '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}'
                  : 'All dates'),
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  initialDateRange: _selectedDateRange,
                );
                if (range != null) setState(() => _selectedDateRange = range);
              },
            ),
          ],
        ),
      ),
      actions: [
        // Reset Filter Button
        TextButton(
          onPressed: () {
            setState(() {
              _selectedType = null;
              _selectedMainCategory = null;
              _selectedSubCategory = null;
              _selectedDateRange = null;
            });
          },
          child: Text('Reset'),
        ),
        // Cancel Button
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        // Apply Filter Button
        TextButton(
          onPressed: () {
            final filter = TransactionFilter(
              type: _selectedType,
              mainCategory: _selectedMainCategory,
              subCategory: _selectedSubCategory,
              dateRange: _selectedDateRange,
            );
            Navigator.pop(context, filter);
          },
          child: Text('Apply'),
        ),
      ],
    );
  }
}

// Extension method to capitalize first letter
extension StringCapitalization on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}