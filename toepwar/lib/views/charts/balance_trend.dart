import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../utils/api_constants.dart';

class BalanceTrendChart extends StatefulWidget {
  final String token;
  final Key? refreshKey;

  BalanceTrendChart({
    required this.token,
    this.refreshKey,
  }) : super(key: refreshKey);

  @override
  _BalanceTrendChartState createState() => _BalanceTrendChartState();
}

class _BalanceTrendChartState extends State<BalanceTrendChart> {
  List<BalancePoint> _balancePoints = [];
  bool _isLoading = true;
  String _selectedInterval = 'Monthly'; // Default to monthly view
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    _initializeDates();
    _fetchTransactions();
  }

  void _initializeDates() {
    final now = DateTime.now();
    // Default to showing last 30 days for daily view
    // Last 12 months for monthly view
    // Last 5 years for yearly view
    switch (_selectedInterval) {
      case 'Daily':
        _selectedStartDate = now.subtract(Duration(days: 30));
        _selectedEndDate = now;
        break;
      case 'Monthly':
        _selectedStartDate = DateTime(now.year - 1, now.month, 1);
        _selectedEndDate = now;
        break;
      case 'Yearly':
        _selectedStartDate = DateTime(now.year - 5, 1, 1);
        _selectedEndDate = now;
        break;
    }
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/gettransactions'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> transactions = json.decode(response.body);
        _processTransactions(transactions);
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load balance data')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _processTransactions(List<dynamic> transactions) {
    // Sort transactions by date
    transactions.sort((a, b) =>
        DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

    Map<String, double> balanceMap = {};
    double runningBalance = 0;

    for (var transaction in transactions) {
      DateTime date = DateTime.parse(transaction['date']);
      if (date.isBefore(_selectedStartDate!) || date.isAfter(_selectedEndDate!)) {
        continue;
      }

      double amount = transaction['amount'].toDouble();
      if (transaction['type'] == 'income') {
        runningBalance += amount;
      } else {
        runningBalance -= amount;
      }

      String key;
      switch (_selectedInterval) {
        case 'Daily':
          key = DateFormat('yyyy-MM-dd').format(date);
          break;
        case 'Monthly':
          key = DateFormat('yyyy-MM').format(date);
          break;
        case 'Yearly':
          key = DateFormat('yyyy').format(date);
          break;
        default:
          key = DateFormat('yyyy-MM').format(date);
      }

      balanceMap[key] = runningBalance;
    }

    _balancePoints = balanceMap.entries.map((entry) {
      return BalancePoint(
        date: entry.key,
        balance: entry.value,
      );
    }).toList();
  }

  String _formatDate(String date) {
    switch (_selectedInterval) {
      case 'Daily':
        return DateFormat('MMM d').format(DateTime.parse(date));
      case 'Monthly':
        return DateFormat('MMM yy').format(DateTime.parse('$date-01'));
      case 'Yearly':
        return date;
      default:
        return date;
    }
  }

  Widget _buildIntervalSelector() {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'Daily', label: Text('Daily')),
        ButtonSegment(value: 'Monthly', label: Text('Monthly')),
        ButtonSegment(value: 'Yearly', label: Text('Yearly')),
      ],
      selected: {_selectedInterval},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _selectedInterval = newSelection.first;
          _initializeDates();
        });
        _fetchTransactions();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_balancePoints.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Balance Trend',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              _buildIntervalSelector(),
              SizedBox(height: 20),
              Text('No balance data available for selected period'),
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
            Text(
              'Balance Trend',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            _buildIntervalSelector(),
            SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.7,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: _balancePoints.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.balance,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < _balancePoints.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Transform.rotate(
                                angle: _selectedInterval == 'Daily' ? 0.7 : 0,
                                child: Text(
                                  _formatDate(_balancePoints[value.toInt()].date),
                                  style: TextStyle(fontSize: 10),
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
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BalancePoint {
  final String date;
  final double balance;

  BalancePoint({required this.date, required this.balance});
}