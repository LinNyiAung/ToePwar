import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../controllers/language_controller.dart';
import '../../helpers/forecast_section_config.dart';
import '../../l10n/app_localizations.dart';
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
  final ScrollController _scrollController = ScrollController();

  late TutorialCoachMark tutorialCoachMark;
  final timeRangeKey = GlobalKey();
  final summaryKey = GlobalKey();
  final trendChartKey = GlobalKey();
  final categoryKey = GlobalKey();
  final insightsKey = GlobalKey();
  final goalsKey = GlobalKey();
  final editModeKey = GlobalKey();


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _sectionsFuture = ForecastSectionManager.loadSections();
    _fetchForecast();



    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wait for data to load before showing tutorial
      if (!_isLoading && _forecastData != null) {
        final prefs = await SharedPreferences.getInstance();
        bool hasSeenTutorial = prefs.getBool('has_seen_forecast_tutorial') ?? false;

        if (!hasSeenTutorial) {
          // Add slight delay to ensure UI is fully rendered
          Future.delayed(Duration(milliseconds: 500), () {
            _showTutorial();
            prefs.setBool('has_seen_forecast_tutorial', true);
          });
        }
      }
    });
  }


  void _initializeTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: Theme.of(context).primaryColor,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        print("Forecast tutorial finished");
      },
      onSkip: () {
        print("Forecast tutorial skipped");
        return true;
      },
      focusAnimationDuration: Duration(milliseconds: 300),
      pulseAnimationDuration: Duration(milliseconds: 500),
      onClickTarget: (target) {
        _scrollToTarget(target);
      },
      onClickOverlay: (target) {
        _scrollToTarget(target);
      },
    );
  }


  void _scrollToTarget(TargetFocus target) {
    if (target.keyTarget?.currentContext == null) return;

    final RenderBox renderBox = target.keyTarget!.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final scrollOffset = position.dy;

    final screenHeight = MediaQuery.of(context).size.height;
    final targetCenter = scrollOffset - (screenHeight / 2) + (renderBox.size.height / 2);

    _scrollController.animateTo(
      targetCenter.clamp(0, _scrollController.position.maxScrollExtent),
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }


  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];


    targets.add(
      TargetFocus(
        identify: "edit_mode",
        keyTarget: editModeKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Padding(
                padding: const EdgeInsets.only(top: 70),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Customize Your View",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      "Toggle edit mode to reorganize sections based on your preferences. Drag and drop sections to reorder them.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );



    targets.add(
      TargetFocus(
        identify: "time_range",
        keyTarget: timeRangeKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Forecast Period",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Adjust the time range to see predictions for different periods, from 1 to 24 months ahead.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );



    targets.add(
      TargetFocus(
        identify: "summary",
        keyTarget: summaryKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Financial Summary",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Quick overview of your projected income, expenses, and savings for the selected period.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );



    targets.add(
      TargetFocus(
        identify: "trend_chart",
        keyTarget: trendChartKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Forecast Trends",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Visual representation of your financial trends over time. Track income, expenses, and savings projections.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );


    targets.add(
      TargetFocus(
        identify: "categories",
        keyTarget: categoryKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Category Forecasts",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Detailed breakdown of projected spending and income by category.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );


    targets.add(
      TargetFocus(
        identify: "insights",
        keyTarget: insightsKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Financial Insights",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "AI-powered analysis of your financial patterns with personalized recommendations.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );


    targets.add(
      TargetFocus(
        identify: "goals",
        keyTarget: goalsKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 150),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Goal Projections",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      "Track progress towards your financial goals with probability estimates and required actions.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );


    return targets;
  }


  void _showTutorial() {
    _initializeTutorial();
    tutorialCoachMark.show(context: context);
  }

  Future<void> _fetchForecast() async {
    setState(() => _isLoading = true);

    try {
      // Get current language from LanguageController
      final languageCode = context.read<LanguageController>().currentLocale.languageCode;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/financial-forecast?forecast_months=$_forecastMonths&language=$languageCode'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _forecastData = json.decode(response.body);

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final prefs = await SharedPreferences.getInstance();
            bool hasSeenTutorial = prefs.getBool('has_seen_forecast_tutorial') ?? false;

            if (!hasSeenTutorial) {
              // Add slight delay to ensure UI is fully rendered
              Future.delayed(Duration(milliseconds: 500), () {
                _showTutorial();
                prefs.setBool('has_seen_forecast_tutorial', true);
              });
            }
          });
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
        title: Text(AppLocalizations.of(context).translate('financialForecast'),
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            key: editModeKey,
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
                    content: Text(AppLocalizations.of(context).translate('sectionOrderSaved')),
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
            controller: _scrollController,
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
                        Text(AppLocalizations.of(context).translate('dragSectionsToReorder')),
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
      key: timeRangeKey,
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
              AppLocalizations.of(context).translate('forecastPeriod'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '$_forecastMonths ' + AppLocalizations.of(context).translate('months'),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  AppLocalizations.of(context).translate('monthRange'),
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
      key: trendChartKey,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).translate('forecastTrends'), style: Theme.of(context).textTheme.titleLarge),
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
      key: categoryKey,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).translate('categoryForecasts'), style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            ExpansionTile(
              title: Text(AppLocalizations.of(context).translate('incomeCategories')),
              children: _buildCategoryList(categoryForecasts['income'], Colors.green),
            ),
            ExpansionTile(
              title: Text(AppLocalizations.of(context).translate('expenseCategories')),
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
      key: goalsKey,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).translate('goalProjections'), style: Theme.of(context).textTheme.titleLarge),
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
          Text(AppLocalizations.of(context).translate('monthlyRequired') +
              '${formatter.format(goal['monthly_required'])}',
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
      key: insightsKey,
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
                    AppLocalizations.of(context).translate('financialInsights'),
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
                AppLocalizations.of(context).translate('actionItems'),
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
                AppLocalizations.of(context).translate('growthOpportunities'),
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
        AppLocalizations.of(context).translate('projectedIncome'),
        getLastAmount(_forecastData!['income_forecast']),
        Icons.trending_up,
        Colors.green,
      ),
      _buildSummaryCard(
        AppLocalizations.of(context).translate('projectedExpenses'),
        getLastAmount(_forecastData!['expense_forecast']),
        Icons.trending_down,
        Colors.red,
      ),
      _buildSummaryCard(
        AppLocalizations.of(context).translate('projectedSavings'),
        getLastAmount(_forecastData!['savings_forecast']),
        Icons.savings,
        Colors.blue,
      ),
    ];

    return Container(
      key: summaryKey,
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