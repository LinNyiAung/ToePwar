import 'package:flutter/material.dart';
import 'package:toepwar/views/transaction/transaction_filter.dart';

import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../dashboard/widgets/drawer_widget.dart';
import '../dashboard/widgets/transaction_list_item.dart';
import 'add_transaction_view.dart';
import 'edit_transaction_view.dart';

class TransactionHistoryView extends StatefulWidget {
  final String token;
  final VoidCallback onTransactionChanged;

  TransactionHistoryView({
    required this.token,
    required this.onTransactionChanged,  // Add this line
  });

  @override
  _TransactionHistoryViewState createState() => _TransactionHistoryViewState();
}

class _TransactionHistoryViewState extends State<TransactionHistoryView> {
  late final TransactionController _transactionController;
  bool _isLoading = false;
  TransactionFilter? _currentFilter;

  @override
  void initState() {
    super.initState();
    _transactionController = TransactionController(token: widget.token);
  }

  Future<void> _deleteTransaction(String transactionId) async {
    setState(() => _isLoading = true);

    try {
      await _transactionController.deleteTransaction(transactionId);
      widget.onTransactionChanged();
      setState(() {}); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editTransaction(TransactionModel transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionView(
          token: widget.token,
          transaction: transaction,
          onTransactionChanged: widget.onTransactionChanged,
        ),
      ),
    );

    if (result == true) {
      setState(() {}); // Refresh the list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () async {
              final filter = await showDialog<TransactionFilter>(
                context: context,
                builder: (context) => TransactionFilterDialog(
                  initialFilter: _currentFilter,
                ),
              );
              setState(() => _currentFilter = filter);
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      drawer: DrawerWidget(  // Use the DrawerWidget here
        token: widget.token,
        onTransactionChanged: widget.onTransactionChanged,
      ),
      body: FutureBuilder<List<TransactionModel>>(
        future: _transactionController.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final transactions = snapshot.data!;
          if (transactions.isEmpty) {
            return Center(
              child: Text('No transactions found'),
            );
          }

          final filteredTransactions = transactions
              .where((t) => _currentFilter?.apply(t) ?? true)
              .toList();

          if (filteredTransactions.isEmpty) {
            return Center(child: Text('No transactions match the filter'));
          }

          return ListView.builder(
              itemCount: filteredTransactions.length,
            itemBuilder: (context, index) {
              final transaction = filteredTransactions[index];
              return TransactionListItem(
                transaction: transaction,
                onDelete: () => _deleteTransaction(transaction.id),
                onEdit: () => _editTransaction(transaction),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionView(token: widget.token, onTransactionChanged: widget.onTransactionChanged,),
            ),
          );
          if (result == true) {
            setState(() {}); // Refresh the list
          }
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}