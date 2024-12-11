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
  int? _selectedYear;
  List<int> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _fetchMonthlyExpenses();
  }

  Future<void> _fetchMonthlyExpenses() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/gettransactions'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> transactions = json.decode(response.body);
        Map<String, double> monthlyTotals = {};
        Set<int> years = {};

        // Process transactions to get monthly totals and available years
        for (var transaction in transactions) {
          if (transaction['type'] == 'expense') {
            DateTime date = DateTime.parse(transaction['date']);
            String monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            years.add(date.year);

            monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) +
                (transaction['amount'] as num).toDouble();
          }
        }

        // Update available years
        _availableYears = years.toList()..sort((a, b) => b.compareTo(a));

        // Set selected year to most recent if not already set
        if (_selectedYear == null && _availableYears.isNotEmpty) {
          _selectedYear = _availableYears.first;
        }

        // Filter expenses for selected year
        _monthlyExpenses = monthlyTotals.entries
            .where((entry) => entry.key.startsWith(_selectedYear.toString()))
            .map((entry) {
          return MonthlyExpense(
            month: entry.key,
            amount: entry.value,
          );
        }).toList()
          ..sort((a, b) => a.month.compareTo(b.month));

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
    return months[monthIndex];
  }

  Widget _buildYearDropdown() {
    return DropdownButton<int>(
      value: _selectedYear,
      hint: Text('Select Year'),
      items: _availableYears.map((year) {
        return DropdownMenuItem<int>(
          value: year,
          child: Text(year.toString()),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          _selectedYear = newValue;
        });
        _fetchMonthlyExpenses();
      },
    );
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Expenses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildYearDropdown(),
                ],
              ),
              SizedBox(height: 20),
              Text('No expense data available for selected year'),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Expenses',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildYearDropdown(),
              ],
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