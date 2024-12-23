import 'package:flutter/material.dart';
import 'package:toepwar/views/dashboard/widgets/drawer_widget.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/dashboard_model.dart';
import '../../models/goal_model.dart';
import '../../models/transaction_model.dart';
import '../charts/balance_trend.dart';
import '../charts/expense_structure_pie.dart';
import '../charts/income_structure_pie.dart';
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
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshDashboard,
          ),
        ],
      ),
      drawer: DrawerWidget(
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
              return _buildErrorView(snapshot.error);
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
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildErrorView(dynamic error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Error: ${error.toString()}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshDashboard,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(Dashboard dashboard, List<Transaction> transactions) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(

            color: Theme.of(context).primaryColor,
            child: Column(
              children: [
                _buildSummaryCards(dashboard),
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildRecentTransactions(transactions),
              SizedBox(height: 24),
              _buildRecentGoals(dashboard.recentGoals),
              SizedBox(height: 24),
              BalanceTrendChart(token: widget.token),
              SizedBox(height: 24),
              ExpensePieChart(token: widget.token),
              SizedBox(height: 24),
              IncomePieChart(token: widget.token),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(Dashboard dashboard) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Financial Overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSummaryCard(
                  'Income',
                  dashboard.totalIncome,
                  Icons.arrow_upward,
                  Colors.green,
                ),
                SizedBox(width: 16),
                _buildSummaryCard(
                  'Expense',
                  dashboard.totalExpense,
                  Icons.arrow_downward,
                  Colors.red,
                ),
                SizedBox(width: 16),
                _buildSummaryCard(
                  'Balance',
                  dashboard.balance,
                  Icons.account_balance_wallet,
                  dashboard.balance >= 0 ? Colors.blue : Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildRecentGoals(List<Goal> goals) {
    if (goals.isEmpty) {
      return Card(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No active goals'),
          ),
        ),
      );
    }

    return Card(
      color: Theme.of(context).cardColor,
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
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No recent transactions'),
          ),
        ),
      );
    }

    return Card(
      color: Theme.of(context).cardColor,
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