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
  String _selectedInterval = 'Monthly';
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  double? _minBalance;
  double? _maxBalance;
  bool _showGridLines = true;

  String _formatCompactNumber(double number) {
    if (number.abs() >= 1000000000) {
      return 'K${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number.abs() >= 1000000) {
      return 'K${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number.abs() >= 1000) {
      return 'K${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return 'K${number.toStringAsFixed(0)}';
    }
  }

  final currencyFormatter = NumberFormat.currency(symbol: 'K');

  @override
  void initState() {
    super.initState();
    _initializeDates();
    _fetchTransactions();
  }

  void _initializeDates() {
    final now = DateTime.now();
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
        SnackBar(
          content: Text('Failed to load balance data'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _processTransactions(List<dynamic> transactions) {
    transactions.sort((a, b) =>
        DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

    Map<String, double> balanceMap = {};
    double runningBalance = 0;
    _minBalance = double.infinity;
    _maxBalance = double.negativeInfinity;

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

      String key = _getDateKey(date);
      balanceMap[key] = runningBalance;

      _minBalance = _minBalance!.compareTo(runningBalance) <= 0
          ? _minBalance
          : runningBalance;
      _maxBalance = _maxBalance!.compareTo(runningBalance) >= 0
          ? _maxBalance
          : runningBalance;
    }

    _balancePoints = balanceMap.entries.map((entry) {
      return BalancePoint(
        date: entry.key,
        balance: entry.value,
      );
    }).toList();
  }

  String _getDateKey(DateTime date) {
    switch (_selectedInterval) {
      case 'Daily':
        return DateFormat('yyyy-MM-dd').format(date);
      case 'Monthly':
        return DateFormat('yyyy-MM').format(date);
      case 'Yearly':
        return DateFormat('yyyy').format(date);
      default:
        return DateFormat('yyyy-MM').format(date);
    }
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

  Widget _buildBalanceStats() {
    if (_minBalance == null || _maxBalance == null) return SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Lowest', _minBalance!),
          _buildStatCard('Highest', _maxBalance!),
          _buildStatCard('Current', _balancePoints.last.balance),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, double value) {
    Color textColor = value < 0 ? Colors.red : Colors.green;

    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          _formatCompactNumber(value),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        color: Theme.of(context).cardColor,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_balancePoints.isEmpty) {
      return Card(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Balance Trend',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 10),
              _buildIntervalSelector(),
              SizedBox(height: 20),
              Icon(Icons.show_chart, size: 48, color: Colors.grey),
              Text('No balance data available for selected period'),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Balance Trend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            _buildIntervalSelector(),
            _buildBalanceStats(),
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
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          Color dotColor = spot.y < 0
                              ? Colors.red
                              : Colors.green;
                          return FlDotCirclePainter(
                            radius: 4,
                            color: dotColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.4),
                            Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _balancePoints.length > 10 ? 2 : 1,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < _balancePoints.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Transform.rotate(
                                angle: _selectedInterval == 'Daily' ? 0.7 : 0,
                                child: Text(
                                  _formatDate(_balancePoints[value.toInt()].date),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
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
                            _formatCompactNumber(value),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).textTheme.bodySmall?.color,
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
                    show: _showGridLines,
                    drawHorizontalLine: true,
                    drawVerticalLine: true,
                    horizontalInterval: (_maxBalance! - _minBalance!) / 5,
                  ),
                  borderData: FlBorderData(show: true),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(

                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineBarSpot spot) {
                          final date = _balancePoints[spot.x.toInt()].date;
                          return LineTooltipItem(
                            '${_formatDate(date)}\n${_formatCompactNumber(spot.y)}',
                            TextStyle(
                              color: spot.y < 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
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