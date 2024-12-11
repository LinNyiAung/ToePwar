import 'package:flutter/material.dart';
import 'package:toepwar/views/charts/income_structure_pie.dart';
import 'package:toepwar/views/charts/monthly_income_bar.dart';


import '../dashboard/widgets/drawer_widget.dart';
import '../transaction/add_transaction_view.dart';

class IncomeStructureView extends StatefulWidget {
  final String token;

  IncomeStructureView({required this.token});

  @override
  _IncomeStructureViewState createState() => _IncomeStructureViewState();
}

class _IncomeStructureViewState extends State<IncomeStructureView> {
  Key _refreshKey = UniqueKey();
  Key _refreshKey2 = UniqueKey();


  void _refreshData() {
    setState(() {
      // Update the key to force rebuild of child widgets
      _refreshKey = UniqueKey();
      _refreshKey2 = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Income Charts'),
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
              MonthlyIncomeChart(token: widget.token,refreshKey: _refreshKey,),
              SizedBox(height: 20),
              IncomePieChart(token: widget.token, refreshKey: _refreshKey2,),
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