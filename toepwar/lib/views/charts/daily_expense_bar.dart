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
  double _totalMonthlyExpense = 0;
  double _averageDailyExpense = 0;
  final _compactCurrencyFormat = NumberFormat.compactCurrency(
    locale: 'en_US',
    symbol: '\$',
  );

  @override
  void initState() {
    super.initState();
    _fetchDailyExpenses();
  }

  Future<void> _fetchDailyExpenses() async {
    try {
      setState(() => _isLoading = true);

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/gettransactions'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> transactions = json.decode(response.body);
        Map<String, double> dailyTotals = {};
        Set<DateTime> months = {};

        // Process transactions
        for (var transaction in transactions) {
          if (transaction['type'] == 'expense') {
            DateTime date = DateTime.parse(transaction['date']);
            DateTime monthKey = DateTime(date.year, date.month, 1);
            months.add(monthKey);
          }
        }

        _availableMonths = months.toList()..sort((a, b) => b.compareTo(a));

        if (_selectedMonth == null && _availableMonths.isNotEmpty) {
          _selectedMonth = _availableMonths.first;
        }

        // Filter transactions for selected month
        List<dynamic> filteredTransactions = transactions.where((transaction) {
          if (transaction['type'] == 'expense') {
            DateTime date = DateTime.parse(transaction['date']);
            return date.year == _selectedMonth!.year &&
                date.month == _selectedMonth!.month;
          }
          return false;
        }).toList();

        // Calculate daily totals and monthly statistics
        _totalMonthlyExpense = 0;
        for (var transaction in filteredTransactions) {
          DateTime date = DateTime.parse(transaction['date']);
          String dateKey = DateFormat('yyyy-MM-dd').format(date);
          double amount = (transaction['amount'] as num).toDouble();
          dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + amount;
          _totalMonthlyExpense += amount;
        }

        _averageDailyExpense = dailyTotals.isEmpty
            ? 0
            : _totalMonthlyExpense / dailyTotals.length;

        _dailyExpenses = dailyTotals.entries
            .map((entry) => DailyExpense(
          date: entry.key,
          amount: entry.value,
        ))
            .toList()
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
    return DateFormat('MMM d').format(date);
  }

  Widget _buildMonthDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<DateTime>(
        value: _selectedMonth,
        hint: Text('Select Month'),
        underline: Container(),
        items: _availableMonths.map((month) {
          return DropdownMenuItem<DateTime>(
            value: month,
            child: Text(
              DateFormat('MMMM yyyy').format(month),
              style: TextStyle(fontSize: 16),
            ),
          );
        }).toList(),
        onChanged: (DateTime? newValue) {
          setState(() => _selectedMonth = newValue);
          _fetchDailyExpenses();
        },
      ),
    );
  }

  Widget _buildStatistics() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard(
          'Monthly Total',
          currencyFormat.format(_totalMonthlyExpense),
          Icons.calendar_month,
        ),
        _buildStatCard(
          'Daily Average',
          currencyFormat.format(_averageDailyExpense),
          Icons.show_chart,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 12)),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        color: Theme.of(context).cardColor,
        elevation: 2,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            SizedBox(height: 24),
            _buildStatistics(),
            SizedBox(height: 24),
            if (_dailyExpenses.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.show_chart, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No expense data available for selected month',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              AspectRatio(
                aspectRatio: 1.7,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _dailyExpenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b) * 1.2,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipPadding: EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${_formatDate(_dailyExpenses[group.x].date)}\n${NumberFormat.currency(symbol: '\$').format(rod.toY)}',
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
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value >= 0 && value < _dailyExpenses.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('d').format(DateTime.parse(_dailyExpenses[value.toInt()].date)),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                            return Text(
                              _compactCurrencyFormat.format(value),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            );
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
                      drawVerticalLine: false,
                      horizontalInterval: 1000,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                        left: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    barGroups: _dailyExpenses.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.amount,
                            gradient: LinearGradient(
                              colors: [Colors.redAccent, Colors.red],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 16,
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