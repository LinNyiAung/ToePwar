import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../utils/api_constants.dart';
import '../charts/balance_trend.dart';
import '../dashboard/widgets/drawer_widget.dart';

class FinancialReportView extends StatefulWidget {
  final String token;

  FinancialReportView({required this.token});

  @override
  _FinancialReportViewState createState() => _FinancialReportViewState();
}

class _FinancialReportViewState extends State<FinancialReportView> {
  DateTime? _startDate;
  DateTime _endDate = DateTime.now();
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);

    try {
      // Build URL with optional start date
      String url = '${ApiConstants.baseUrl}/financial-report?end_date=${_endDate.toIso8601String()}';
      if (_startDate != null) {
        url += '&start_date=${_startDate!.toIso8601String()}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() => _reportData = json.decode(response.body));
      } else {
        throw Exception('Failed to load report');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading report: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetFilter() {
    setState(() {
      _startDate = null;
      _endDate = DateTime.now();
    });
    _fetchReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Financial Report', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          // Show current filter status
          if (_startDate != null)
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  '${DateFormat('MM/dd/yyyy').format(_startDate!)} - ${DateFormat('MM/dd/yyyy').format(_endDate)}',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          // Date range picker button
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _showDateRangePicker,
          ),
          // Reset filter button - only show when filter is active
          if (_startDate != null)
            IconButton(
              icon: Icon(Icons.filter_alt_off),
              tooltip: 'Reset to all-time view',
              onPressed: _resetFilter,
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchReport,
          ),
        ],
      ),
      drawer: DrawerWidget(
        token: widget.token,
        onTransactionChanged: (){},
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _reportData == null
          ? Center(child: Text('No data available'))
          : _buildReport(),
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchReport();
    }
  }

  Widget _buildReport() {
    final summary = _reportData!['summary'];
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildSummaryCard(summary, currencyFormat),
        SizedBox(height: 16),
        _buildCategoryBreakdown('Income by Category', _reportData!['income_by_category'], Colors.green),
        SizedBox(height: 16),
        _buildCategoryBreakdown('Expense by Category', _reportData!['expense_by_category'], Colors.red),
        SizedBox(height: 16),
        _buildGoalsProgress(),
        SizedBox(height: 16),
        BalanceTrendChart(token: widget.token),
      ],
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary, NumberFormat format) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
        children: [
          Text('Financial Summary', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 16),
          _buildSummaryRow('Total Income', summary['total_income'], format, Colors.green),
          _buildSummaryRow('Total Expenses', summary['total_expense'], format, Colors.red),
          Divider(),
          _buildSummaryRow('Net Income', summary['net_income'], format,
              summary['net_income'] >= 0 ? Colors.blue : Colors.orange),
        ],
      ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, NumberFormat format, Color color) {
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

  Widget _buildCategoryBreakdown(String title, List<dynamic> categories, Color color) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            ...categories.map((category) => _buildCategoryRow(
              category['category'],
              category['amount'],
              color,
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(String category, double amount, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(category),
          Text(
            NumberFormat.currency(symbol: '\$').format(amount),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsProgress() {
    final goals = _reportData!['goals_summary'];
    if (goals.isEmpty) return SizedBox.shrink();

    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Savings Goals', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            ...goals.map((goal) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal['name'], style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: goal['progress'] / 100,
                  backgroundColor: Colors.grey[200],
                  color: goal['completed'] ? Colors.green : Theme.of(context).primaryColor,
                ),
                SizedBox(height: 4),
                Text(
                  '${NumberFormat.currency(symbol: '\$').format(goal['current_amount'])} '
                      'of ${NumberFormat.currency(symbol: '\$').format(goal['target_amount'])} '
                      '(${NumberFormat.percentPattern().format(goal['progress'] / 100)})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(height: 16),
              ],
            )).toList(),
          ],
        ),
      ),
    );
  }


}