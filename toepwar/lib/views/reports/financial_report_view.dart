import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../utils/api_constants.dart';
import '../charts/balance_trend.dart';
import '../dashboard/widgets/drawer_widget.dart';

class FinancialReportView extends StatefulWidget {
  final String token;

  const FinancialReportView({Key? key, required this.token}) : super(key: key);

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
        SnackBar(
          content: Text('Error loading report: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: DrawerWidget(token: widget.token, onTransactionChanged: () {}),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportData == null
          ? _buildNoDataView()
          : _buildReport(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      iconTheme: IconThemeData(color: Colors.white),
      title: const Text(
        'Financial Report',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        if (_startDate != null)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${DateFormat('MM/dd/yy').format(_startDate!)} - ${DateFormat('MM/dd/yy').format(_endDate)}',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.white),
          onPressed: _showDateRangePicker,
        ),
        if (_startDate != null)
          IconButton(
            icon: const Icon(Icons.filter_alt_off, color: Colors.white),
            tooltip: 'Reset to all-time view',
            onPressed: _resetFilter,
          ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _fetchReport,
        ),
      ],
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _fetchReport,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReport() {
    final summary = _reportData!['summary'];
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCards(summary, currencyFormat),
        const SizedBox(height: 24),
        _buildCategoryBreakdown(
          'Income by Category',
          _reportData!['income_by_category'],
          Colors.green.shade100,
          Colors.green,
        ),
        const SizedBox(height: 24),
        _buildCategoryBreakdown(
          'Expense by Category',
          _reportData!['expense_by_category'],
          Colors.red.shade100,
          Colors.red,
        ),
        const SizedBox(height: 24),
        _buildGoalsProgress(),
        const SizedBox(height: 24),
        BalanceTrendChart(token: widget.token),
      ],
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary, NumberFormat format) {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildSummaryCard(
            'Total Income',
            summary['total_income'],
            Icons.trending_up,
            Colors.green,
            format,
          ),
          _buildSummaryCard(
            'Total Expenses',
            summary['total_expense'],
            Icons.trending_down,
            Colors.red,
            format,
          ),
          _buildSummaryCard(
            'Net Income',
            summary['net_income'],
            summary['net_income'] >= 0 ? Icons.account_balance : Icons.warning,
            summary['net_income'] >= 0 ? Colors.blue : Colors.orange,
            format,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title,
      double value,
      IconData icon,
      Color color,
      NumberFormat format,
      ) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              icon,
              size: 80,
              color: color.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  format.format(value),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(
      String title,
      List<dynamic> categories,
      Color backgroundColor,
      Color textColor,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              ],
            ),
            const SizedBox(height: 16),
            ...categories.map((category) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(category['category']),
                      Text(
                        NumberFormat.currency(symbol: '\$')
                            .format(category['amount']),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: category['amount'] /
                        (categories as List)
                            .map((c) => c['amount'] as double)
                            .reduce((a, b) => a + b),
                    backgroundColor: backgroundColor,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsProgress() {
    final goals = _reportData!['goals_summary'];
    if (goals.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Savings Goals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.stars, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 16),
            ...goals.map((goal) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        goal['name'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (goal['completed'])
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: goal['progress'] / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        goal['completed']
                            ? Colors.green
                            : Theme.of(context).primaryColor,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${NumberFormat.currency(symbol: '\$').format(goal['current_amount'])} of ${NumberFormat.currency(symbol: '\$').format(goal['target_amount'])}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${goal['progress']}%',
                        style: TextStyle(
                          color: goal['completed']
                              ? Colors.green
                              : Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchReport();
    }
  }

  void _resetFilter() {
    setState(() {
      _startDate = null;
      _endDate = DateTime.now();
    });
    _fetchReport();
  }
}