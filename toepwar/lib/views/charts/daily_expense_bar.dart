import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../utils/api_constants.dart';

class DailyExpenseChart extends StatefulWidget {
  final String token;
  final Key? refreshKey;

  DailyExpenseChart({
    required this.token,
    this.refreshKey,
  }) : super(key: refreshKey);

  @override
  _DailyExpenseChartState createState() => _DailyExpenseChartState();
}

class _DailyExpenseChartState extends State<DailyExpenseChart> {
  List<DailyExpense> _dailyExpenses = [];
  bool _isLoading = true;
  DateTime? _selectedMonth;
  List<DateTime> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    _fetchDailyExpenses();
  }

  Future<void> _fetchDailyExpenses() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/gettransactions'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> transactions = json.decode(response.body);
        Map<String, double> dailyTotals = {};
        Set<DateTime> months = {};

        // Process transactions to get daily totals and available months
        for (var transaction in transactions) {
          if (transaction['type'] == 'expense') {
            DateTime date = DateTime.parse(transaction['date']);

            // Track available months (first of month for easier comparison)
            DateTime monthKey = DateTime(date.year, date.month, 1);
            months.add(monthKey);
          }
        }

        // Update available months
        _availableMonths = months.toList()..sort((a, b) => b.compareTo(a));

        // Set selected month to most recent if not already set
        if (_selectedMonth == null && _availableMonths.isNotEmpty) {
          _selectedMonth = _availableMonths.first;
        }

        // Filter and process transactions for the selected month
        List<dynamic> filteredTransactions = transactions.where((transaction) {
          if (transaction['type'] == 'expense') {
            DateTime date = DateTime.parse(transaction['date']);
            return date.year == _selectedMonth!.year &&
                date.month == _selectedMonth!.month;
          }
          return false;
        }).toList();

        // Calculate daily totals for filtered transactions
        for (var transaction in filteredTransactions) {
          DateTime date = DateTime.parse(transaction['date']);
          String dateKey = DateFormat('yyyy-MM-dd').format(date);
          dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) +
              (transaction['amount'] as num).toDouble();
        }

        // Transform daily totals to DailyExpense objects
        _dailyExpenses = dailyTotals.entries
            .map((entry) {
          return DailyExpense(
            date: entry.key,
            amount: entry.value,
          );
        }).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        setState(() => _isLoading = false);
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      print('Error fetching daily expenses: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String dateKey) {
    DateTime date = DateTime.parse(dateKey);
    return DateFormat('d').format(date);
  }

  Widget _buildMonthDropdown() {
    return DropdownButton<DateTime>(
      value: _selectedMonth,
      hint: Text('Select Month'),
      items: _availableMonths.map((month) {
        return DropdownMenuItem<DateTime>(
          value: month,
          child: Text(DateFormat('MMM yyyy').format(month)),
        );
      }).toList(),
      onChanged: (DateTime? newValue) {
        setState(() {
          _selectedMonth = newValue;
        });
        _fetchDailyExpenses();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_dailyExpenses.isEmpty) {
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
                    'Daily Expenses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildMonthDropdown(),
                ],
              ),
              SizedBox(height: 20),
              Text('No expense data available for selected month'),
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
                  'Daily Expenses',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildMonthDropdown(),
              ],
            ),
            SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _dailyExpenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b) * 1.2,
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
                          if (value >= 0 && value < _dailyExpenses.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _formatDate(_dailyExpenses[value.toInt()].date),
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
                  barGroups: _dailyExpenses.asMap().entries.map((entry) {
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

class DailyExpense {
  final String date;
  final double amount;

  DailyExpense({required this.date, required this.amount});
}