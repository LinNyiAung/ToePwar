import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionListItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: transaction.type == 'income'
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          transaction.type == 'income'
              ? Icons.arrow_downward
              : Icons.arrow_upward,
          color: transaction.type == 'income' ? Colors.green : Colors.red,
          size: 20,
        ),
      ),
      title: Text(
        transaction.category,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        '${dateFormat.format(transaction.date)}\n${timeFormat.format(transaction.date)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Text(
        '\$${transaction.amount.toStringAsFixed(2)}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: transaction.type == 'income' ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      isThreeLine: true,
    );
  }
}