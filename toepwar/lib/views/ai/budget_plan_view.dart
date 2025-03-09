import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../controllers/language_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/api_constants.dart';
import '../dashboard/widgets/drawer_widget.dart';

class BudgetPlanView extends StatefulWidget {
  final String token;

  BudgetPlanView({required this.token});

  @override
  _BudgetPlanViewState createState() => _BudgetPlanViewState();
}

class _BudgetPlanViewState extends State<BudgetPlanView> {
  Map<String, dynamic>? _budgetPlan;
  bool _isLoading = false;
  String _selectedPeriod = 'monthly';

  final ScrollController _scrollController = ScrollController();


  // Add these new variables
  late TutorialCoachMark tutorialCoachMark;
  final periodKey = GlobalKey();
  final summaryKey = GlobalKey();
  final categoryBudgetsKey = GlobalKey();
  final recommendationsKey = GlobalKey();


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchBudgetPlan();

    // Add this to show tutorial after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wait for data to load before showing tutorial
      if (!_isLoading && _budgetPlan != null) {
        final prefs = await SharedPreferences.getInstance();
        bool hasSeenTutorial = prefs.getBool('has_seen_budget_plan_tutorial') ?? false;

        if (!hasSeenTutorial) {
          // Add slight delay to ensure UI is fully rendered
          Future.delayed(Duration(milliseconds: 500), () {
            _showTutorial();
            prefs.setBool('has_seen_budget_plan_tutorial', true);
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
        print("Tutorial finished");
      },
      onSkip: () {
        print("Tutorial skipped");
        return true;
      },
      // Add this function to handle scrolling
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
    final RenderBox renderBox = target.keyTarget?.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final scrollOffset = position.dy;

    // Calculate the scroll position to center the target
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
        identify: "period",
        keyTarget: periodKey,
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
                    "Plan Period",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Choose Period foe budget plan",
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
                    "Plan Overview",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Overview include Total budget, Saving Target and Period",
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
        identify: "category_budgets",
        keyTarget: categoryBudgetsKey,
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
                    "Category Budgets",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Budgets for each categories",
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
        identify: "recommendations",
        keyTarget: recommendationsKey,
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
                    "Recommendations",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Ai recommendations",
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



    // Add more targets for amount, category, and add button...
    // Similar structure as above

    return targets;
  }

  void _showTutorial() {
    print("Attempting to show tutorial");
    _initializeTutorial();
    print("Tutorial initialized");
    tutorialCoachMark.show(context: context);
    print("Tutorial show method called");
  }

  Future<void> _fetchBudgetPlan() async {
    setState(() => _isLoading = true);

    try {
      // Get current language from LanguageController
      final languageCode = context.read<LanguageController>().currentLocale.languageCode;
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/budget-plan?period_type=$_selectedPeriod&language=$languageCode'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() => _budgetPlan = json.decode(response.body));

        // Add this: Check if we should show tutorial after data loads
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final prefs = await SharedPreferences.getInstance();
          bool hasSeenTutorial = prefs.getBool('has_seen_budget_plan_tutorial') ?? false;

          if (!hasSeenTutorial) {
            // Add slight delay to ensure UI is fully rendered
            Future.delayed(Duration(milliseconds: 500), () {
              _showTutorial();
              prefs.setBool('has_seen_budget_plan_tutorial', true);
            });
          }
        });
      } else {
        throw Exception('Failed to load budget plan');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading budget plan: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          AppLocalizations.of(context).translate('aiBudgetPlan'),
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchBudgetPlan,
          ),
        ],
      ),
      drawer: DrawerWidget(
        token: widget.token,
        onTransactionChanged: () => _fetchBudgetPlan(),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _budgetPlan == null
          ? _buildEmptyState()
          : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).translate('noBudgetPlan'),
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _fetchBudgetPlan,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: Theme.of(context).primaryColor,
            child: Column(
              children: [
                _buildPeriodSelector(),
                _buildSummaryCards(),
                SizedBox(height: 20),
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildCategoryBudgets(),
              SizedBox(height: 16),
              _buildRecommendations(),
              SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      key: periodKey,
      margin: EdgeInsets.all(16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).translate('budgetPeriod'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  items: [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedPeriod = newValue);
                      _fetchBudgetPlan();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final currencyFormat = NumberFormat.currency(symbol: 'K');
    return Container(
      key: summaryKey,
      height: 150,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildSummaryCard(
            AppLocalizations.of(context).translate('totalBudget'),
            _budgetPlan!['total_budget'],
            Icons.account_balance_wallet,
            Colors.blue,
            currencyFormat,
          ),
          SizedBox(width: 16,),
          _buildSummaryCard(
            AppLocalizations.of(context).translate('savingsTarget'),
            _budgetPlan!['savings_target'],
            Icons.savings,
            Colors.green,
            currencyFormat,
          ),
          SizedBox(width: 16,),
          _buildDateRangeCard(
            DateFormat('MMM d').format(DateTime.parse(_budgetPlan!['start_date'])),
            DateFormat('MMM d').format(DateTime.parse(_budgetPlan!['end_date'])),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title,
      double amount,
      IconData icon,
      Color color,
      NumberFormat format,
      ) {
    return Container(
      width: 200,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              icon,
              size: 80,
              color: color.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  format.format(amount),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeCard(String startDate, String endDate) {
    return Container(
      width: 180,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.calendar_today, color: Colors.purple),
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).translate('period'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              '$startDate - $endDate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBudgets() {
    final categoryBudgets = Map<String, double>.from(_budgetPlan!['category_budgets']);
    final totalBudget = _budgetPlan!['total_budget'] as double;
    final currencyFormat = NumberFormat.currency(symbol: 'K');

    return Card(
      key: categoryBudgetsKey,
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).translate('categoryBudgets'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...categoryBudgets.entries.map((entry) {
              // Ensure widthFactor is between 0 and 1
              final widthFactor = totalBudget > 0 ?
              (entry.value / totalBudget).clamp(0.0, 1.0) : 0.0;

              final percentage = totalBudget > 0 ?
              (entry.value / totalBudget * 100).toStringAsFixed(1) : '0.0';

              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text(
                          currencyFormat.format(entry.value),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: widthFactor,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = List<String>.from(_budgetPlan!['recommendations']);

    return Card(
      key: recommendationsKey,
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).translate('aiRecommendations'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...recommendations.map((recommendation) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates,
                        color: Theme.of(context).primaryColor, size: 20),
                    SizedBox(width: 12),
                    Expanded(child: Text(recommendation)),
                  ],
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}