import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/api_constants.dart';

class MonthlyExpenseChart extends StatefulWidget {
  final String token;
  final Key? refreshKey;

  MonthlyExpenseChart({
    required this.token,
    this.refreshKey,
  }) : super(key: refreshKey);

  @override
  _MonthlyExpenseChartState createState() => _MonthlyExpenseChartState();
}

class _MonthlyExpenseChartState extends State<MonthlyExpenseChart> {
  List<MonthlyExpense> _monthlyExpenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMonthlyExpenses();
  }

  Future<void> _fetchMonthlyExpenses() async {
    try {
      // Get all transactions
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/gettransactions'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> transactions = json.decode(response.body);

        // Process transactions to get monthly totals
        Map<String, double> monthlyTotals = {};

        for (var transaction in transactions) {
          if (transaction['type'] == 'expense') {
            DateTime date = DateTime.parse(transaction['date']);
            String monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

            monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) +
                (transaction['amount'] as num).toDouble();
          }
        }

        // Convert to list and sort by date
        _monthlyExpenses = monthlyTotals.entries.map((entry) {
          return MonthlyExpense(
            month: entry.key,
            amount: entry.value,
          );
        }).toList()
          ..sort((a, b) => a.month.compareTo(b.month));

        // Keep only the last 6 months
        if (_monthlyExpenses.length > 6) {
          _monthlyExpenses = _monthlyExpenses.sublist(_monthlyExpenses.length - 6);
        }

        setState(() => _isLoading = false);
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      print('Error fetching monthly expenses: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatMonth(String monthKey) {
    final parts = monthKey.split('-');
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthIndex = int.parse(parts[1]) - 1;
    return '${months[monthIndex]}\n${parts[0].substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_monthlyExpenses.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Center(child: Text('No monthly expense data available')),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Monthly Expenses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _monthlyExpenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(

                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '\$${rod.toY.toStringAsFixed(2)}',
                          TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < _monthlyExpenses.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _formatMonth(_monthlyExpenses[value.toInt()].month),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text('\$${value.toInt()}');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1000,
                  ),
                  borderData: FlBorderData(
                    show: true,
                  ),
                  barGroups: _monthlyExpenses.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.amount,
                          color: Colors.blue,
                          width: 22,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MonthlyExpense {
  final String month;
  final double amount;

  MonthlyExpense({required this.month, required this.amount});
}