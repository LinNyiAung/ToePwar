import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../l10n/app_localizations.dart';
import '../../utils/api_constants.dart';

class MonthlyIncomeChart extends StatefulWidget {
  final String token;
  final Key? refreshKey;

  MonthlyIncomeChart({
    required this.token,
    this.refreshKey,
  }) : super(key: refreshKey);

  @override
  _MonthlyIncomeChartState createState() => _MonthlyIncomeChartState();
}

class _MonthlyIncomeChartState extends State<MonthlyIncomeChart> {
  List<MonthlyIncome> _monthlyIncomes = [];
  bool _isLoading = true;
  int? _selectedYear;
  List<int> _availableYears = [];
  double _totalYearlyIncome = 0;
  double _averageMonthlyIncome = 0;
  final _compactCurrencyFormat = NumberFormat.compactCurrency(
    locale: 'en_US',
    symbol: 'K',
  );

  @override
  void initState() {
    super.initState();
    _fetchMonthlyIncomes();
  }

  Future<void> _fetchMonthlyIncomes() async {
    try {
      setState(() => _isLoading = true);

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/gettransactions'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> transactions = json.decode(response.body);
        Map<String, double> monthlyTotals = {};
        Set<int> years = {};

        // Process transactions
        for (var transaction in transactions) {
          if (transaction['type'] == 'income') {
            DateTime date = DateTime.parse(transaction['date']);
            String monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            years.add(date.year);

            monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) +
                (transaction['amount'] as num).toDouble();
          }
        }

        _availableYears = years.toList()..sort((a, b) => b.compareTo(a));

        if (_selectedYear == null && _availableYears.isNotEmpty) {
          _selectedYear = _availableYears.first;
        }

        // Filter incomes for selected year and calculate statistics
        _totalYearlyIncome = 0;
        var filteredTotals = monthlyTotals.entries
            .where((entry) => entry.key.startsWith(_selectedYear.toString()));

        for (var entry in filteredTotals) {
          _totalYearlyIncome += entry.value;
        }

        _monthlyIncomes = filteredTotals.map((entry) {
          return MonthlyIncome(
            month: entry.key,
            amount: entry.value,
          );
        }).toList()..sort((a, b) => a.month.compareTo(b.month));

        _averageMonthlyIncome = _monthlyIncomes.isEmpty
            ? 0
            : _totalYearlyIncome / _monthlyIncomes.length;

        setState(() => _isLoading = false);
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      print('Error fetching monthly incomes: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatMonth(String monthKey) {
    final date = DateTime.parse('$monthKey-01');
    return DateFormat('MMM').format(date);
  }

  Widget _buildYearDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<int>(
        value: _selectedYear,
        hint: Text(AppLocalizations.of(context).translate('selectYear')),
        underline: Container(),
        items: _availableYears.map((year) {
          return DropdownMenuItem<int>(
            value: year,
            child: Text(
              year.toString(),
              style: TextStyle(fontSize: 16),
            ),
          );
        }).toList(),
        onChanged: (int? newValue) {
          setState(() => _selectedYear = newValue);
          _fetchMonthlyIncomes();
        },
      ),
    );
  }

  Widget _buildStatistics() {
    final currencyFormat = NumberFormat.currency(symbol: 'K');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard(
          AppLocalizations.of(context).translate('yearlyTotal'),
          currencyFormat.format(_totalYearlyIncome),
          Icons.calendar_today,
        ),
        _buildStatCard(
          AppLocalizations.of(context).translate('monthlyAverage'),
          currencyFormat.format(_averageMonthlyIncome),
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
                color: Colors.green,
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
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).translate('monthlyIncome'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildYearDropdown(),
              ],
            ),
            SizedBox(height: 24),
            _buildStatistics(),
            SizedBox(height: 24),
            if (_monthlyIncomes.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.show_chart, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).translate('noIncomeDataYear'),
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
                    maxY: _monthlyIncomes.map((e) => e.amount).reduce((a, b) => a > b ? a : b) * 1.2,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipPadding: EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${_formatMonth(_monthlyIncomes[group.x].month)}\n${NumberFormat.currency(symbol: 'K').format(rod.toY)}',
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
                            if (value >= 0 && value < _monthlyIncomes.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _formatMonth(_monthlyIncomes[value.toInt()].month),
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
                    barGroups: _monthlyIncomes.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.amount,
                            gradient: LinearGradient(
                              colors: [Colors.greenAccent, Colors.green],
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

class MonthlyIncome {
  final String month;
  final double amount;

  MonthlyIncome({required this.month, required this.amount});
}