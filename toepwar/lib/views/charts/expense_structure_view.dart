import 'package:flutter/material.dart';
import 'package:toepwar/views/charts/daily_expense_bar.dart';
import 'expense_structure_pie.dart';
import 'monthly_expense_bar.dart';
import '../dashboard/widgets/drawer_widget.dart';
import '../transaction/add_transaction_view.dart';

class ExpenseStructureView extends StatefulWidget {
  final String token;

  ExpenseStructureView({required this.token});

  @override
  _ExpenseStructureViewState createState() => _ExpenseStructureViewState();
}

class _ExpenseStructureViewState extends State<ExpenseStructureView> {
  Key _refreshKey = UniqueKey();
  Key _refreshKey2 = UniqueKey();
  Key _refreshKey3 = UniqueKey();


  void _refreshData() {
    setState(() {
      // Update the key to force rebuild of child widgets
      _refreshKey = UniqueKey();
      _refreshKey2 = UniqueKey();
      _refreshKey3 = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Charts'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      drawer: DrawerWidget(
        token: widget.token,
        onTransactionChanged: _refreshData,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExpensePieChart(token: widget.token, refreshKey: _refreshKey2,),
              SizedBox(height: 20),
              MonthlyExpenseChart(token: widget.token,refreshKey: _refreshKey,),
              SizedBox(height: 20),
              DailyExpenseChart(token: widget.token, refreshKey: _refreshKey3,),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionView(
                token: widget.token,
                onTransactionChanged: _refreshData,
              ),
            ),
          );
          if (result == true) {
            _refreshData();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}