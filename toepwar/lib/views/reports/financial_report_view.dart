import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../helpers/report_section_config.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/api_constants.dart';
import '../charts/balance_trend.dart';
import '../dashboard/widgets/drawer_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:cross_file/cross_file.dart';

class FinancialReportView extends StatefulWidget {
  final String token;

  const FinancialReportView({Key? key, required this.token}) : super(key: key);

  @override
  _FinancialReportViewState createState() => _FinancialReportViewState();
}

class _FinancialReportViewState extends State<FinancialReportView> {
  DateTime? _startDate;
  DateTime _endDate = DateTime.now();
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;
  bool _isEditMode = false;
  late Future<List<ReportSectionConfig>> _sectionsFuture;

  late TutorialCoachMark tutorialCoachMark;
  final GlobalKey dateRangeKey = GlobalKey();
  final GlobalKey editLayoutKey = GlobalKey();
  final GlobalKey exportKey = GlobalKey();
  final GlobalKey summaryCardsKey = GlobalKey();
  final GlobalKey incomeBreakdownKey = GlobalKey();
  final GlobalKey expenseBreakdownKey = GlobalKey();
  final GlobalKey goalsKey = GlobalKey();
  final GlobalKey trendChartKey = GlobalKey();

  final ScrollController _scrollController = ScrollController();


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _sectionsFuture = ReportSectionManager.loadSections();
    _fetchReport();


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wait for data to load before showing tutorial
      if (!_isLoading && _reportData != null) {
        final prefs = await SharedPreferences.getInstance();
        bool hasSeenTutorial = prefs.getBool('has_seen_financial_report_tutorial') ?? false;

        if (!hasSeenTutorial) {
          // Add slight delay to ensure UI is fully rendered
          Future.delayed(Duration(milliseconds: 500), () {
            _showTutorial();
            prefs.setBool('hhas_seen_financial_report_tutorial', true);
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
        print("Financial report tutorial finished");
      },
      onSkip: () {
        print("Financial report tutorial skipped");
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
    final RenderBox renderBox = target.keyTarget?.currentContext!.findRenderObject() as RenderBox;
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
        identify: "date_range",
        keyTarget: dateRangeKey,
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
                    "Date Range",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Filter with date",
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
        identify: "edit_layout",
        keyTarget: editLayoutKey,
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
        identify: "export_options",
        keyTarget: exportKey,
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
                    "Export Financial Report",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Export your financial report in excel or pdf format",
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
        identify: "summary_cards",
        keyTarget: summaryCardsKey,
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
                    "This include income, expense and date range",
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
        identify: "income_breakdown",
        keyTarget: incomeBreakdownKey,
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
                    "Income Breakdown",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Income categories",
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
        identify: "expense_breakdown",
        keyTarget: expenseBreakdownKey,
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
                    "Expense Breakdown",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Expense Categories",
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

    // Add more targets for category breakdown, goals, and trend chart...
    // Similar structure as above

    return targets;
  }


  void _showTutorial() {
    _initializeTutorial();
    tutorialCoachMark.show(context: context);
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);

    try {
      String url = '${ApiConstants.baseUrl}/financial-report?end_date=${_endDate.toIso8601String()}';
      if (_startDate != null) {
        url += '&start_date=${_startDate!.toIso8601String()}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() => _reportData = json.decode(response.body));

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final prefs = await SharedPreferences.getInstance();
          bool hasSeenTutorial = prefs.getBool('has_seen_financial_report_tutorial') ?? false;

          if (!hasSeenTutorial) {
            // Add slight delay to ensure UI is fully rendered
            Future.delayed(Duration(milliseconds: 500), () {
              _showTutorial();
              prefs.setBool('has_seen_financial_report_tutorial', true);
            });
          }
        });
      } else {
        throw Exception('Failed to load report');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading report: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSection(ReportSection section) {
    if (_reportData == null) return const SizedBox.shrink();

    switch (section) {
      case ReportSection.summary:
        return _buildSummaryCards(_reportData!['summary'], NumberFormat.currency(symbol: 'K'));
      case ReportSection.incomeCategory:
        return _buildCategoryBreakdown(
          AppLocalizations.of(context).translate('incomeByCategoryTitle'),
          _reportData!['income_by_category'],
          Colors.green.shade100,
          Colors.green,
          incomeBreakdownKey,
        );
      case ReportSection.expenseCategory:
        return _buildCategoryBreakdown(
          AppLocalizations.of(context).translate('expenseByCategoryTitle'),
          _reportData!['expense_by_category'],
          Colors.red.shade100,
          Colors.red,
          expenseBreakdownKey,
        );
      case ReportSection.goalsProgress:
        return _buildGoalsProgress();
      case ReportSection.balanceTrend:
        return BalanceTrendChart(token: widget.token);
    }
  }

  Future<void> _reorderSections(int oldIndex, int newIndex, List<ReportSectionConfig> sections) async {
    if (!_isEditMode) return;

    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = sections.removeAt(oldIndex);
      sections.insert(newIndex, item);
    });
    await ReportSectionManager.saveSections(sections);
  }


  Future<void> _exportReport() async {
    setState(() => _isLoading = true);

    try {
      String url = '${ApiConstants.baseUrl}/export-financial-report?end_date=${_endDate.toIso8601String()}';
      if (_startDate != null) {
        url += '&start_date=${_startDate!.toIso8601String()}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        // Get the temporary directory for storing the file
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'financial_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
        final filePath = '${directory.path}/$fileName';

        // Write the file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Share the file using the updated method
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Financial Report',
        );
      } else {
        throw Exception('Failed to export report');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting report: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _exportReportPDF() async {
    setState(() => _isLoading = true);

    try {
      String url = '${ApiConstants.baseUrl}/export-financial-report-pdf?end_date=${_endDate.toIso8601String()}';
      if (_startDate != null) {
        url += '&start_date=${_startDate!.toIso8601String()}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        // Get the temporary directory for storing the file
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'financial_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
        final filePath = '${directory.path}/$fileName';

        // Write the file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Share the file
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Financial Report PDF',
        );
      } else {
        throw Exception('Failed to export PDF report');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting PDF report: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: DrawerWidget(token: widget.token, onTransactionChanged: () {}),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<ReportSectionConfig>>(
        future: _sectionsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sections = snapshot.data!;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              if (_isEditMode)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 16),
                        SizedBox(width: 8),
                        Text(AppLocalizations.of(context).translate('dragSectionsToReorder'),),
                      ],
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.drag_handle,
                                      color: Colors.white,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      iconTheme: IconThemeData(color: Colors.white),
      title:  Text(
        AppLocalizations.of(context).translate('financialReport'),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        if (_startDate != null)
          Center(
            child: Container(

              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${DateFormat('MM/dd/yy').format(_startDate!)} - ${DateFormat('MM/dd/yy').format(_endDate)}',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        IconButton(
          key: editLayoutKey,
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
          key: dateRangeKey,
          icon: const Icon(Icons.calendar_today, color: Colors.white),
          onPressed: _showDateRangePicker,
        ),
        if (_startDate != null)
          IconButton(
            icon: const Icon(Icons.filter_alt_off, color: Colors.white),
            tooltip: 'Reset to all-time view',
            onPressed: _resetFilter,
          ),
        PopupMenuButton<String>(
          key: exportKey,
          icon: const Icon(Icons.download, color: Colors.white),
          onSelected: (String choice) {
            if (choice == 'excel') {
              _exportReport();
            } else if (choice == 'pdf') {
              _exportReportPDF();
            }
          },
          itemBuilder: (BuildContext context) => [
             PopupMenuItem<String>(
              value: 'excel',
              child: Text(AppLocalizations.of(context).translate('exportAsExcel')),
            ),
             PopupMenuItem<String>(
              value: 'pdf',
              child: Text(AppLocalizations.of(context).translate('exportAsPDF')),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _fetchReport,
        ),
      ],
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).translate('noDataAvailable'),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _fetchReport,
            icon: const Icon(Icons.refresh),
            label:  Text(AppLocalizations.of(context).translate('refresh')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReport() {
    final summary = _reportData!['summary'];
    final currencyFormat = NumberFormat.currency(symbol: 'K');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCards(summary, currencyFormat),
        const SizedBox(height: 24),
        _buildCategoryBreakdown(
          AppLocalizations.of(context).translate('incomeByCategoryTitle'),
          _reportData!['income_by_category'],
          Colors.green.shade100,
          Colors.green,
          incomeBreakdownKey,
        ),
        const SizedBox(height: 24),
        _buildCategoryBreakdown(
          AppLocalizations.of(context).translate('expenseByCategoryTitle'),
          _reportData!['expense_by_category'],
          Colors.red.shade100,
          Colors.red,
          expenseBreakdownKey,
        ),
        const SizedBox(height: 24),
        _buildGoalsProgress(),
        const SizedBox(height: 24),
        BalanceTrendChart(token: widget.token),
      ],
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary, NumberFormat format) {
    return SizedBox(
      key: summaryCardsKey,
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildSummaryCard(
            AppLocalizations.of(context).translate('totalIncome'),
            summary['total_income'],
            Icons.trending_up,
            Colors.green,
            format,
          ),
          SizedBox(width: 16,),
          _buildSummaryCard(
            AppLocalizations.of(context).translate('totalExpense'),
            summary['total_expense'],
            Icons.trending_down,
            Colors.red,
            format,
          ),
          SizedBox(width: 16,),
          _buildSummaryCard(
            AppLocalizations.of(context).translate('netIncome'),
            summary['net_income'],
            summary['net_income'] >= 0 ? Icons.account_balance : Icons.warning,
            summary['net_income'] >= 0 ? Colors.blue : Colors.orange,
            format,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title,
      double value,
      IconData icon,
      Color color,
      NumberFormat format,
      ) {
    return Container(
      width: 180,

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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  format.format(value),
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

  Widget _buildCategoryBreakdown(
      String title,
      List<dynamic> categories,
      Color backgroundColor,
      Color textColor,
      GlobalKey key,
      ) {
    return Card(
      key: key,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              ],
            ),
            const SizedBox(height: 16),
            ...categories.map((category) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(category['category']),
                      Text(
                        NumberFormat.currency(symbol: 'K')
                            .format(category['amount']),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: category['amount'] /
                        (categories as List)
                            .map((c) => c['amount'] as double)
                            .reduce((a, b) => a + b),
                    backgroundColor: backgroundColor,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsProgress() {
    final goals = _reportData!['goals_summary'];
    if (goals.isEmpty) return const SizedBox.shrink();

    return Card(
      key: goalsKey,
      color: Theme.of(context).cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).translate('savingsGoals'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.stars, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 16),
            ...goals.map((goal) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        goal['name'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (goal['completed'])
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:  Text(
                            AppLocalizations.of(context).translate('completed'),
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: goal['progress'] / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        goal['completed']
                            ? Colors.green
                            : Theme.of(context).primaryColor,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${NumberFormat.currency(symbol: 'K').format(goal['current_amount'])} of ${NumberFormat.currency(symbol: 'K').format(goal['target_amount'])}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${goal['progress']}%',
                        style: TextStyle(
                          color: goal['completed']
                              ? Colors.green
                              : Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchReport();
    }
  }

  void _resetFilter() {
    setState(() {
      _startDate = null;
      _endDate = DateTime.now();
    });
    _fetchReport();
  }
}