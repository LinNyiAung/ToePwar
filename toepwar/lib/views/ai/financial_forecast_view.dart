import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../../helpers/forecast_section_config.dart';
import '../../utils/api_constants.dart';
import '../dashboard/widgets/drawer_widget.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _isEditMode = false;
  late Future<List<ForecastSectionConfig>> _sectionsFuture;


  @override
  void initState() {
    super.initState();
    _sectionsFuture = ForecastSectionManager.loadSections();
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
        setState(() {
          _forecastData = json.decode(response.body);
        });
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


  Widget _buildSection(ForecastSection section) {
    if (_forecastData == null) return const SizedBox.shrink();

    switch (section) {
      case ForecastSection.timeRange:
        return _buildTimeRangeSelector();
      case ForecastSection.summary:
        return _buildSummaryCards();
      case ForecastSection.forecastTrend:
        return _buildForecastChart();
      case ForecastSection.categoryForecasts:
        return _buildCategoryForecasts();
      case ForecastSection.insights:
        return _buildInsightsAndRecommendations();
      case ForecastSection.goalProjections:
        return _buildGoalProjections();
    }
  }

  Future<void> _reorderSections(int oldIndex, int newIndex, List<ForecastSectionConfig> sections) async {
    if (!_isEditMode) return;

    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = sections.removeAt(oldIndex);
      sections.insert(newIndex, item);
    });
    await ForecastSectionManager.saveSections(sections);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Financial Forecast',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(
              _isEditMode ? Icons.check : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
              if (!_isEditMode) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Section order saved'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
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
          : FutureBuilder<List<ForecastSectionConfig>>(
        future: _sectionsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final sections = snapshot.data!;

          return CustomScrollView(
            slivers: [
              if (_isEditMode)
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 16),
                        SizedBox(width: 8),
                        Text('Drag sections to reorder'),
                      ],
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverReorderableList(
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    return ReorderableDragStartListener(
                      key: Key(section.section.toString()),
                      index: index,
                      enabled: _isEditMode,
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              _buildSection(section.section),
                              if (_isEditMode)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.9),
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.drag_handle,
                                      color: Colors.white,
                                    ),
                                    padding: EdgeInsets.all(8),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
                  onReorder: (oldIndex, newIndex) =>
                      _reorderSections(oldIndex, newIndex, sections),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildForecastContent() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildTimeRangeSelector(),
        _buildSummaryCards(),
        _buildForecastChart(),
        _buildInsightsAndRecommendations(),
        _buildCategoryForecasts(),
        _buildGoalProjections(),

      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(16),
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
      child: Material(  // Added Material widget here
        color: Colors.transparent,  // Make it transparent to keep your existing styling
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forecast Period',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '$_forecastMonths months',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '(1-24 months)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Theme.of(context).primaryColor,
                inactiveTrackColor: Colors.grey[200],
                thumbColor: Theme.of(context).primaryColor,
                overlayColor: Theme.of(context).primaryColor.withOpacity(0.1),
                trackHeight: 4,
              ),
              child: Slider(
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
      color: Theme.of(context).cardColor,
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
            (i) {
          var amount = data[i]['amount'];
          // Convert amount to double regardless of type
          double value = amount is int ? amount.toDouble() : (amount as double);
          return FlSpot(i.toDouble(), value);
        },
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
      color: Theme.of(context).cardColor,
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
    final formatter = NumberFormat.currency(symbol: 'K');
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
      color: Theme.of(context).cardColor,
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

    final formatter = NumberFormat.currency(symbol: 'K');

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
  }



  Widget _buildInsightsAndRecommendations() {
    if (_forecastData == null) return SizedBox.shrink();

    final forecastInsight = _forecastData!['forecast_insight'];
    final recommendations = List<Map<String, dynamic>>.from(_forecastData!['recommendations'] ?? []);
    final riskLevel = _forecastData!['risk_level'] ?? 'Unknown';
    final opportunityAreas = List<Map<String, dynamic>>.from(_forecastData!['opportunity_areas'] ?? []);

    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Financial Insights',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _buildRiskLevelBadge(riskLevel),
              ],
            ),
            SizedBox(height: 16),
            if (forecastInsight != null) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.insights,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        forecastInsight,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],
            if (recommendations.isNotEmpty) ...[
              Text(
                'Action Items',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: recommendations.length,
                separatorBuilder: (context, index) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final recommendation = recommendations[index];
                  return _buildRecommendationCard(recommendation);
                },
              ),
              SizedBox(height: 24),
            ],
            if (opportunityAreas.isNotEmpty) ...[
              Text(
                'Growth Opportunities',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: opportunityAreas.length,
                separatorBuilder: (context, index) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final opportunity = opportunityAreas[index];
                  return _buildOpportunityCard(opportunity);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildRiskLevelBadge(String riskLevel) {
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (riskLevel.toLowerCase()) {
      case 'high':
        backgroundColor = Colors.red;
        break;
      case 'medium':
        backgroundColor = Colors.orange;
        break;
      case 'low':
        backgroundColor = Colors.green;
        break;
      default:
        backgroundColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: textColor,
          ),
          SizedBox(width: 4),
          Text(
            '$riskLevel Risk',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final priority = recommendation['priority'] ?? 'Low';
    Color priorityColor;

    switch (priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.green;
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  recommendation['category'] ?? '',
                  style: TextStyle(
                    color: priorityColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$priority Priority',
                  style: TextStyle(
                    color: priorityColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            recommendation['action'] ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (recommendation['impact'] != null) ...[
            SizedBox(height: 8),
            Text(
              recommendation['impact'],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildOpportunityCard(Map<String, dynamic> opportunity) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.green,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                opportunity['category'] ?? '',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            opportunity['description'] ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (opportunity['potential_impact'] != null) ...[
            SizedBox(height: 8),
            Text(
              opportunity['potential_impact'],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildSummaryCards() {
    if (_forecastData == null) return const SizedBox.shrink();

    // Safely get the last values with null handling and type conversion
    double getLastAmount(List<dynamic>? forecast) {
      if (forecast == null || forecast.isEmpty) return 0.0;
      var lastAmount = forecast.last['amount'];
      if (lastAmount == null) return 0.0;
      // Convert to double regardless of whether it's int or double
      return lastAmount is int ? lastAmount.toDouble() : (lastAmount as double);
    }

    final cards = [
      _buildSummaryCard(
        'Projected Income',
        getLastAmount(_forecastData!['income_forecast']),
        Icons.trending_up,
        Colors.green,
      ),
      _buildSummaryCard(
        'Projected Expenses',
        getLastAmount(_forecastData!['expense_forecast']),
        Icons.trending_down,
        Colors.red,
      ),
      _buildSummaryCard(
        'Projected Savings',
        getLastAmount(_forecastData!['savings_forecast']),
        Icons.savings,
        Colors.blue,
      ),
    ];

    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                NumberFormat.currency(symbol: 'K').format(amount),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}