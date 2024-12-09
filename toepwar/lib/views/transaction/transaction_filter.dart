// transaction_filter.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/transaction_model.dart';
import '../../utils/api_constants.dart';

class TransactionFilter {
  final String? type;
  final String? category;
  final DateTimeRange? dateRange;

  TransactionFilter({this.type, this.category, this.dateRange});

  bool apply(Transaction transaction) {
    bool matchesFilters = true;

    // Only check type if it's selected (not null and not 'All')
    if (type != null && type!.isNotEmpty && type != 'All') {
      matchesFilters = matchesFilters && transaction.type == type;
    }

    // Only check category if it's selected
    if (category != null && category!.isNotEmpty && category != 'All') {
      matchesFilters = matchesFilters && transaction.category == category;
    }

    // Only check date range if it's selected
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
  String? selectedType;
  String? selectedCategory;
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    selectedType = widget.initialFilter?.type;
    selectedCategory = widget.initialFilter?.category;
    selectedDateRange = widget.initialFilter?.dateRange;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Filter Transactions'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: selectedType,
            decoration: InputDecoration(labelText: 'Type'),
            items: ['income', 'expense'].map((type) =>
                DropdownMenuItem(value: type, child: Text(type))
            ).toList()..insert(0, DropdownMenuItem(child: Text('All'))),
            onChanged: (value) => setState(() => selectedType = value),
          ),
          DropdownButtonFormField<String>(
            value: selectedCategory,
            decoration: InputDecoration(labelText: 'Category'),
            items: [...ApiConstants.transactionCategories['income']!,
              ...ApiConstants.transactionCategories['expense']!]
                .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                .toList()..insert(0, DropdownMenuItem(child: Text('All'))),
            onChanged: (value) => setState(() => selectedCategory = value),
          ),
          ListTile(
            title: Text('Date Range'),
            subtitle: Text(selectedDateRange != null
                ? '${DateFormat('MMM d').format(selectedDateRange!.start)} - ${DateFormat('MMM d').format(selectedDateRange!.end)}'
                : 'All dates'),
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                initialDateRange: selectedDateRange,
              );
              if (range != null) setState(() => selectedDateRange = range);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final filter = TransactionFilter(
              type: selectedType,
              category: selectedCategory,
              dateRange: selectedDateRange,
            );
            Navigator.pop(context, filter);
          },
          child: Text('Apply'),
        ),
      ],
    );
  }
}