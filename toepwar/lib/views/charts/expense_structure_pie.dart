// First, add fl_chart to pubspec.yaml:
// fl_chart: ^0.65.0

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/api_constants.dart';

class ExpensePieChart extends StatefulWidget {
  final String token;

  ExpensePieChart({required this.token});

  @override
  _ExpensePieChartState createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  List<ExpenseCategory> _categories = [];
  bool _isLoading = true;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _fetchExpenseCategories();
  }

  Future<void> _fetchExpenseCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/expense-categories'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _categories = data
              .map((item) => ExpenseCategory(
                    category: item['category'],
                    amount: item['amount'].toDouble(),
                  ))
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load expense categories');
      }
    } catch (e) {
      print('Error fetching expense categories: $e');
      setState(() => _isLoading = false);
    }
  }

  List<PieChartSectionData> _getSections() {
    double total = _categories.fold(0, (sum, item) => sum + item.amount);

    return _categories.asMap().entries.map((entry) {
      final int idx = entry.key;
      final ExpenseCategory category = entry.value;
      final bool isTouched = idx == _touchedIndex;
      final double percentage = (category.amount / total) * 100;

      return PieChartSectionData(
        color: _getColorForIndex(idx),
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: isTouched ? 110 : 100,
        titleStyle: TextStyle(
          fontSize: isTouched ? 18 : 14,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_categories.isEmpty) {
      return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 0),
            child: Center(
                child: Text('No expense data available for chart')),
          ));
    }

    return Card(
      elevation: 2,
      child: Column(
        children: [
          SizedBox(height: 20),
          Text(
            'Expense Distribution',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 1.3,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: _getSections(),
                sectionsSpace: 2,
                centerSpaceRadius: 0,
              ),
            ),
          ),
          SizedBox(height: 10),
          _buildLegend(),
          SizedBox(height: 20),
        ],
      ),

    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _categories.asMap().entries.map((entry) {
        final idx = entry.key;
        final category = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              color: _getColorForIndex(idx),
            ),
            SizedBox(width: 4),
            Text(
              '${category.category}: \$${category.amount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class ExpenseCategory {
  final String category;
  final double amount;

  ExpenseCategory({required this.category, required this.amount});
}
