import 'package:flutter/material.dart';
import 'package:toepwar/views/dashboard/widgets/drawer_widget.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/dashboard_model.dart';
import '../../models/goal_model.dart';
import '../../models/transaction_model.dart';
import '../goals/goals_view.dart';
import '../transaction/add_transaction_view.dart';
import '../transaction/edit_transaction_view.dart';
import '../transaction/transaction_history_view.dart';
import 'widgets/transaction_list_item.dart';

class DashboardView extends StatefulWidget {
  final String token;

  DashboardView({required this.token});

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final DashboardController _dashboardController;
  late Future<List<Transaction>> _recentTransactions;
  late Future<Dashboard> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardController = DashboardController(token: widget.token);
    _recentTransactions = _dashboardController.getRecentTransactions();
    _dashboardData = _dashboardController.getDashboardData();
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _recentTransactions = _dashboardController.getRecentTransactions();
      _dashboardData = _dashboardController.getDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshDashboard,
          ),
        ],
      ),
      drawer: DrawerWidget(  // Use the DrawerWidget here
        token: widget.token,
        onTransactionChanged: _refreshDashboard,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([_dashboardData, _recentTransactions]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshDashboard,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return Center(child: Text('No data available'));
            }

            final dashboard = snapshot.data![0] as Dashboard;
            final transactions = snapshot.data![1] as List<Transaction>;

            return _buildDashboardContent(dashboard, transactions);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionView(token: widget.token, onTransactionChanged: _refreshDashboard,),
            ),
          );
          if (result == true) {
            _refreshDashboard();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildDashboardContent(Dashboard dashboard, List<Transaction> transactions) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildSummaryCard(dashboard),
        SizedBox(height: 24),
        _buildRecentTransactions(transactions),
        SizedBox(height: 24),
        _buildRecentGoals(dashboard.recentGoals),
      ],
    );
  }

  Widget _buildSummaryCard(Dashboard dashboard) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            _buildSummaryItem(
              'Income',
              dashboard.totalIncome,
              Colors.green,
            ),
            SizedBox(height: 8),
            _buildSummaryItem(
              'Expense',
              dashboard.totalExpense,
              Colors.red,
            ),
            SizedBox(height: 8),
            _buildSummaryItem(
              'Balance',
              dashboard.balance,
              dashboard.balance >= 0 ? Colors.blue : Colors.orange,
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  Widget _buildRecentGoals(List<Goal> goals) {
    if (goals.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No active goals'),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Goals',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GoalsView(token: widget.token),
                      ),
                    );
                  },
                  child: Text('See All'),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: goals.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              final goal = goals[index];
              return ListTile(
                title: Text(goal.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: goal.progress / 100,
                      backgroundColor: Colors.grey[200],
                      color: goal.completed ? Colors.green : Theme.of(context).primaryColor,
                    ),
                    SizedBox(height: 4),
                    Text('\$${goal.currentAmount.toStringAsFixed(2)} / \$${goal.targetAmount.toStringAsFixed(2)}'),
                  ],
                ),
                trailing: Text('${goal.progress.toStringAsFixed(1)}%'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No recent transactions'),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionHistoryView(
                          token: widget.token,
                          onTransactionChanged: _refreshDashboard,  // Add this line
                        ),
                      ),
                    );
                  },
                  child: Text('See All'),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return TransactionListItem(
                transaction: transaction,
                onEdit: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTransactionView(
                        token: widget.token,
                        transaction: transaction,
                        onTransactionChanged: _refreshDashboard,
                      ),
                    ),
                  );
                  if (result == true) {
                    _refreshDashboard();
                  }
                },
                onDelete: () async {
                  final controller = TransactionController(token: widget.token);
                  await controller.deleteTransaction(transaction.id);
                  _refreshDashboard();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}