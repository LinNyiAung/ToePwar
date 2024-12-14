import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/api_constants.dart';
import '../dashboard/widgets/drawer_widget.dart';

class FinancialForecastView extends StatefulWidget {
  final String token;

  FinancialForecastView({required this.token});

  @override
  _FinancialForecastViewState createState() => _FinancialForecastViewState();
}

class _FinancialForecastViewState extends State<FinancialForecastView> {
  Map<String, dynamic>? _forecastData;
  bool _isLoading = false;
  int _forecastMonths = 6;

  @override
  void initState() {
    super.initState();
    _fetchForecast();
  }

  Future<void> _fetchForecast() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/financial-forecast?forecast_months=$_forecastMonths'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() => _forecastData = json.decode(response.body));
      } else {
        throw Exception('Failed to load forecast');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading forecast: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Financial Forecast'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchForecast,
          ),
        ],
      ),
      drawer: DrawerWidget(
        token: widget.token,
        onTransactionChanged: () => _fetchForecast(),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _forecastData == null
          ? Center(child: Text('No forecast data available'))
          : _buildForecastContent(),
    );
  }

  Widget _buildForecastContent() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildTimeRangeSelector(),
        SizedBox(height: 16),
        _buildForecastChart(),
        SizedBox(height: 16),
        _buildCategoryForecasts(),
        SizedBox(height: 16),
        _buildGoalProjections(),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Forecast Range', style: Theme.of(context).textTheme.titleLarge),
            Slider(
              value: _forecastMonths.toDouble(),
              min: 1,
              max: 24,
              divisions: 23,
              label: '$_forecastMonths months',
              onChanged: (value) {
                setState(() => _forecastMonths = value.round());
              },
              onChangeEnd: (value) => _fetchForecast(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastChart() {
    final incomeForecast = _forecastData!['income_forecast'];
    final expenseForecast = _forecastData!['expense_forecast'];
    final savingsForecast = _forecastData!['savings_forecast'];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Forecast Trends', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= incomeForecast.length) return Text('');
                          final date = DateTime.parse(incomeForecast[value.toInt()]['date']);
                          return Text(DateFormat('MMM').format(date));
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    _createLineChartBarData(incomeForecast, Colors.green),
                    _createLineChartBarData(expenseForecast, Colors.red),
                    _createLineChartBarData(savingsForecast, Colors.blue),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildChartLegend(),
          ],
        ),
      ),
    );
  }

  LineChartBarData _createLineChartBarData(List<dynamic> data, Color color) {
    return LineChartBarData(
      spots: List.generate(
        data.length,
            (i) => FlSpot(i.toDouble(), data[i]['amount'].toDouble()),
      ),
      color: color,
      dotData: FlDotData(show: false),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Income', Colors.green),
        SizedBox(width: 16),
        _buildLegendItem('Expenses', Colors.red),
        SizedBox(width: 16),
        _buildLegendItem('Savings', Colors.blue),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _buildCategoryForecasts() {
    final categoryForecasts = _forecastData!['category_forecasts'];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category Forecasts', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            ExpansionTile(
              title: Text('Income Categories'),
              children: _buildCategoryList(categoryForecasts['income'], Colors.green),
            ),
            ExpansionTile(
              title: Text('Expense Categories'),
              children: _buildCategoryList(categoryForecasts['expense'], Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryList(Map<String, dynamic> categories, Color color) {
    final formatter = NumberFormat.currency(symbol: '\$');
    return categories.entries.map((entry) {
      final lastMonth = entry.value.last['amount'];
      return ListTile(
        title: Text(entry.key),
        trailing: Text(
          formatter.format(lastMonth),
          style: TextStyle(color: color),
        ),
      );
    }).toList();
  }

  Widget _buildGoalProjections() {
    final goalProjections = _forecastData!['goal_projections'];
    if (goalProjections.isEmpty) return SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Goal Projections', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            ...goalProjections.map((goal) => _buildGoalProjectionItem(goal)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProjectionItem(Map<String, dynamic> goal) {
    final probability = goal['probability'].toDouble();
    final color = probability >= 75 ? Colors.green
        : probability >= 50 ? Colors.orange
        : Colors.red;

    final formatter = NumberFormat.currency(symbol: '\$');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal['name'],
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: probability / 100,
                  backgroundColor: Colors.grey[300],
                  color: color,
                  minHeight: 10,
                ),
              ),
              SizedBox(width: 16),
              Text(
                '${probability.toStringAsFixed(1)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Monthly Required: ${formatter.format(goal['monthly_required'])}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }}