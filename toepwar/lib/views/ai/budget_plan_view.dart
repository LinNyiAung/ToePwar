import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../utils/api_constants.dart';
import '../dashboard/widgets/drawer_widget.dart';

class BudgetPlanView extends StatefulWidget {
  final String token;

  BudgetPlanView({required this.token});

  @override
  _BudgetPlanViewState createState() => _BudgetPlanViewState();
}

class _BudgetPlanViewState extends State<BudgetPlanView> {
  Map<String, dynamic>? _budgetPlan;
  bool _isLoading = false;
  String _selectedPeriod = 'monthly';

  @override
  void initState() {
    super.initState();
    _fetchBudgetPlan();
  }

  Future<void> _fetchBudgetPlan() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/budget-plan?period_type=$_selectedPeriod'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() => _budgetPlan = json.decode(response.body));
      } else {
        throw Exception('Failed to load budget plan');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading budget plan: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Budget Plan'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchBudgetPlan,
          ),
        ],
      ),
      drawer: DrawerWidget(
        token: widget.token,
        onTransactionChanged: () => _fetchBudgetPlan(),
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _budgetPlan == null
                ? Center(child: Text('No budget plan available'))
                : _buildBudgetPlan(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget Period:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            DropdownButton<String>(
              value: _selectedPeriod,
              items: [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedPeriod = newValue;
                  });
                  _fetchBudgetPlan();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetPlan() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildSummaryCard(currencyFormat),
        SizedBox(height: 16),
        _buildCategoryBudgets(currencyFormat),
        SizedBox(height: 16),
        _buildRecommendations(),
      ],
    );
  }

  Widget _buildSummaryCard(NumberFormat format) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Budget Summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            _buildSummaryRow(
              'Total Budget',
              _budgetPlan!['total_budget'],
              format,
              Colors.blue,
            ),
            _buildSummaryRow(
              'Savings Target',
              _budgetPlan!['savings_target'],
              format,
              Colors.green,
            ),
            SizedBox(height: 8),
            Text(
              'Budget Period: ${DateFormat('MMM d').format(DateTime.parse(_budgetPlan!['start_date']))} - ${DateFormat('MMM d').format(DateTime.parse(_budgetPlan!['end_date']))}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String label,
      double value,
      NumberFormat format,
      Color color,
      ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(
            format.format(value),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgets(NumberFormat format) {
    final categoryBudgets = Map<String, double>.from(_budgetPlan!['category_budgets']);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Budgets',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            ...categoryBudgets.entries.map((entry) => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      format.format(entry.value),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ],
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = List<String>.from(_budgetPlan!['recommendations']);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Recommendations',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            ...recommendations.map((recommendation) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(recommendation),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}