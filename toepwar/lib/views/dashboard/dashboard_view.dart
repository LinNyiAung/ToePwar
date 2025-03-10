import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toepwar/views/dashboard/widgets/drawer_widget.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../helpers/section_config.dart';
import '../../l10n/app_localizations.dart';
import '../../models/dashboard_model.dart';
import '../../models/goal_model.dart';
import '../../models/transaction_model.dart';
import '../charts/balance_trend.dart';
import '../charts/expense_structure_pie.dart';
import '../charts/income_structure_pie.dart';
import '../goals/goals_view.dart';
import '../transaction/add_transaction_view.dart';
import '../transaction/edit_transaction_view.dart';
import '../transaction/transaction_history_view.dart';
import 'widgets/transaction_list_item.dart';

class DashboardView extends StatefulWidget {
  final String token;

  DashboardView({required this.token});

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final DashboardController _dashboardController;
  late Future<List<Transaction>> _recentTransactions;
  late Future<Dashboard> _dashboardData;
  late Future<List<SectionConfig>> _sectionsFuture;
  bool _isEditMode = false;

  final ScrollController _scrollController = ScrollController();

  late TutorialCoachMark tutorialCoachMark;
  final overviewKey = GlobalKey();
  final recentTransactionsKey = GlobalKey();
  final recentGoalsKey = GlobalKey();
  final balanceTrendKey = GlobalKey();
  final expenseChartKey = GlobalKey();
  final incomeChartKey = GlobalKey();
  final addKey = GlobalKey();
  final editModeKey = GlobalKey();


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _dashboardController = DashboardController(token: widget.token);
    _recentTransactions = _dashboardController.getRecentTransactions();
    _dashboardData = _dashboardController.getDashboardData();
    _sectionsFuture = DashboardSectionManager.loadSections();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      bool hasSeenTutorial = prefs.getBool('has_seen_dashboard_tutorial') ?? false;

      if (!hasSeenTutorial) {
        _showTutorial();
        await prefs.setBool('has_seen_dashboard_tutorial', true);
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
        print("Dashboard tutorial finished");
      },
      onSkip: () {
        print("Dashboard tutorial skipped");
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
              return Column(
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
              );
            },
          ),
        ],
      ),
    );


    targets.add(
      TargetFocus(
        identify: "overview",
        keyTarget: overviewKey,
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
                    "Financial Overview",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Financial Overview include Income, Expense and Balance",
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
        identify: "recent_transactions",
        keyTarget: recentTransactionsKey,
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
                    "Recent Transactions",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Your recently made transactions",
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
        identify: "recent_goals",
        keyTarget: recentGoalsKey,
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
                    "Recent Goals",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Your created goals",
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
        identify: "balance_trend",
        keyTarget: balanceTrendKey,
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
                      "Balance Trend",
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
                ),
              );
            },
          ),
        ],
      ),
    );


    targets.add(
      TargetFocus(
        identify: "income_chart",
        keyTarget: incomeChartKey,
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
                      "Income Chart",
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
                ),
              );
            },
          ),
        ],
      ),
    );


    targets.add(
      TargetFocus(
        identify: "expense_chart",
        keyTarget: expenseChartKey,
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
                      "Expense Chart",
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


    targets.add(
      TargetFocus(
        identify: "add",
        keyTarget: addKey,
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
                      "Add transactions",
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


    return targets;
  }

  void _showTutorial() {
    _initializeTutorial();
    tutorialCoachMark.show(context: context);
  }

  Widget _buildSection(DashboardSection section, Dashboard dashboard, List<Transaction> transactions) {
    return Container(
      key: Key(section.toString()),
      child: Stack(
        children: [
          // The actual section content
          _buildSectionContent(section, dashboard, transactions),

          // Edit mode overlay
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
    );
  }

  Widget _buildSectionContent(DashboardSection section, Dashboard dashboard, List<Transaction> transactions) {
    switch (section) {
      case DashboardSection.recentTransactions:
        return _buildRecentTransactions(transactions);
      case DashboardSection.recentGoals:
        return _buildRecentGoals(dashboard.recentGoals);
      case DashboardSection.balanceTrend:
        return BalanceTrendChart(token: widget.token);
      case DashboardSection.expenseStructure:
        return ExpensePieChart(token: widget.token);
      case DashboardSection.incomeStructure:
        return IncomePieChart(token: widget.token);
    }
  }

  Future<void> _reorderSections(int oldIndex, int newIndex, List<SectionConfig> sections) async {
    if (!_isEditMode) return;  // Prevent reordering when not in edit mode

    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = sections.removeAt(oldIndex);
      sections.insert(newIndex, item);
    });
    await DashboardSectionManager.saveSections(sections);
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _recentTransactions = _dashboardController.getRecentTransactions();
      _dashboardData = _dashboardController.getDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          AppLocalizations.of(context).translate('dashboard'),
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          // Edit mode toggle button
          IconButton(
            icon: Icon(
              key: editModeKey,
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
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshDashboard,
          ),
        ],
      ),
      drawer: DrawerWidget(
        token: widget.token,
        onTransactionChanged: _refreshDashboard,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([_dashboardData, _recentTransactions, _sectionsFuture]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildErrorView(snapshot.error);
            }

            final dashboard = snapshot.data![0] as Dashboard;
            final transactions = snapshot.data![1] as List<Transaction>;
            final sections = snapshot.data![2] as List<SectionConfig>;

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Fixed Financial Overview Section
                SliverToBoxAdapter(
                  child: Container(
                    key: overviewKey,
                    color: Theme.of(context).primaryColor,
                    child: Column(
                      children: [
                        _buildSummaryCards(dashboard),
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
                // Edit mode indicator
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
                          Text(AppLocalizations.of(context).translate('dragSectionsToReorder'),),
                        ],
                      ),
                    ),
                  ),
                // Reorderable Sections
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverReorderableList(
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return ReorderableDragStartListener(
                        key: Key(section.section.toString()),
                        index: index,
                        enabled: _isEditMode,  // Only enable drag when in edit mode
                        child: Column(
                          children: [
                            _buildSection(section.section, dashboard, transactions),
                            SizedBox(height: 24),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionView(
                token: widget.token,
                onTransactionChanged: _refreshDashboard,
              ),
            ),
          );
          if (result == true) {
            _refreshDashboard();
          }
        },
        child: Icon(key: addKey,Icons.add, color: Colors.white),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildErrorView(dynamic error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Error: ${error.toString()}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshDashboard,
              icon: Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).translate('retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(Dashboard dashboard, List<Transaction> transactions) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(

            color: Theme.of(context).primaryColor,
            child: Column(
              children: [
                _buildSummaryCards(dashboard),
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
              _buildRecentTransactions(transactions),
              SizedBox(height: 24),
              _buildRecentGoals(dashboard.recentGoals),
              SizedBox(height: 24),
              BalanceTrendChart(token: widget.token),
              SizedBox(height: 24),
              ExpensePieChart(token: widget.token),
              SizedBox(height: 24),
              IncomePieChart(token: widget.token),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(Dashboard dashboard) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              AppLocalizations.of(context).translate('financialOverview'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSummaryCard(
                  AppLocalizations.of(context).translate('income'),
                  dashboard.totalIncome,
                  Icons.arrow_upward,
                  Colors.green,
                ),
                SizedBox(width: 16),
                _buildSummaryCard(
                  AppLocalizations.of(context).translate('expense'),
                  dashboard.totalExpense,
                  Icons.arrow_downward,
                  Colors.red,
                ),
                SizedBox(width: 16),
                _buildSummaryCard(
                  AppLocalizations.of(context).translate('balance'),
                  dashboard.balance,
                  Icons.account_balance_wallet,
                  dashboard.balance >= 0 ? Colors.blue : Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            'K${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildRecentGoals(List<Goal> goals) {
    if (goals.isEmpty) {
      return Card(
        key: recentGoalsKey,
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(AppLocalizations.of(context).translate('noActiveGoals')),
          ),
        ),
      );
    }

    return Card(
      key: recentGoalsKey,
      color: Theme.of(context).cardColor,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).translate('recentGoals'),
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GoalsView(token: widget.token),
                      ),
                    );
                  },
                  child: Text(AppLocalizations.of(context).translate('seeAll')),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: goals.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              final goal = goals[index];
              return ListTile(
                title: Text(goal.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: goal.progress / 100,
                      backgroundColor: Colors.grey[200],
                      color: goal.completed ? Colors.green : Theme.of(context).primaryColor,
                    ),
                    SizedBox(height: 4),
                    Text('K${goal.currentAmount.toStringAsFixed(2)} / K${goal.targetAmount.toStringAsFixed(2)}'),
                  ],
                ),
                trailing: Text('${goal.progress.toStringAsFixed(1)}%'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return Card(
        key: recentTransactionsKey,
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(AppLocalizations.of(context).translate('noRecentTransactions')),
          ),
        ),
      );
    }

    return Card(
      key: recentTransactionsKey,
      color: Theme.of(context).cardColor,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).translate('recentTransactions'),
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionHistoryView(
                          token: widget.token,
                          onTransactionChanged: _refreshDashboard,
                        ),
                      ),
                    );
                  },
                  child: Text(AppLocalizations.of(context).translate('seeAll')),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return TransactionListItem(
                transaction: transaction,
                onEdit: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTransactionView(
                        token: widget.token,
                        transaction: transaction,
                        onTransactionChanged: _refreshDashboard,
                      ),
                    ),
                  );
                  if (result == true) {
                    _refreshDashboard();
                  }
                },
                onDelete: () async {
                  final controller = TransactionController(token: widget.token);
                  await controller.deleteTransaction(transaction.id);
                  _refreshDashboard();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}