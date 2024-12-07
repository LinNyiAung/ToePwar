import 'package:flutter/material.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../dashboard/widgets/transaction_list_item.dart';
import 'add_transaction_view.dart';

class TransactionHistoryView extends StatefulWidget {
  final String token;

  TransactionHistoryView({required this.token});

  @override
  _TransactionHistoryViewState createState() => _TransactionHistoryViewState();
}

class _TransactionHistoryViewState extends State<TransactionHistoryView> {
  late final TransactionController _transactionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _transactionController = TransactionController(token: widget.token);
  }

  Future<void> _deleteTransaction(String transactionId) async {
    setState(() => _isLoading = true);

    try {
      await _transactionController.deleteTransaction(transactionId);
      setState(() {}); // Refresh the list
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction History'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: FutureBuilder<List<Transaction>>(
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

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return Dismissible(
                key: Key(transaction.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _deleteTransaction(transaction.id);
                },
                child: TransactionListItem(transaction: transaction),
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
              builder: (context) => AddTransactionView(token: widget.token),
            ),
          );
          if (result == true) {
            setState(() {}); // Refresh the list
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
