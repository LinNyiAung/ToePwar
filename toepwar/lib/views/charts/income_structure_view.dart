import 'package:flutter/material.dart';
import 'package:toepwar/views/charts/daily_income_bar.dart';
import 'package:toepwar/views/charts/income_structure_pie.dart';
import 'package:toepwar/views/charts/monthly_income_bar.dart';


import '../../helpers/income_section_config.dart';
import '../dashboard/widgets/drawer_widget.dart';
import '../transaction/add_transaction_view.dart';

class IncomeStructureView extends StatefulWidget {
  final String token;

  IncomeStructureView({required this.token});

  @override
  _IncomeStructureViewState createState() => _IncomeStructureViewState();
}

class _IncomeStructureViewState extends State<IncomeStructureView> {
  Key _refreshKey = UniqueKey();
  Key _refreshKey2 = UniqueKey();
  Key _refreshKey3 = UniqueKey();
  bool _isEditMode = false;
  late Future<List<IncomeSectionConfig>> _sectionsFuture;


  @override
  void initState() {
    super.initState();
    _sectionsFuture = IncomeSectionManager.loadSections();
  }

  void _refreshData() {
    setState(() {
      // Update the key to force rebuild of child widgets
      _refreshKey = UniqueKey();
      _refreshKey2 = UniqueKey();
      _refreshKey3 = UniqueKey();
    });
  }

  Widget _buildSection(IncomeSection section) {
    switch (section) {
      case IncomeSection.distribution:
        return IncomePieChart(token: widget.token, refreshKey: _refreshKey);
      case IncomeSection.monthly:
        return MonthlyIncomeChart(token: widget.token, refreshKey: _refreshKey2);
      case IncomeSection.daily:
        return DailyIncomeChart(token: widget.token, refreshKey: _refreshKey3);
    }
  }


  Future<void> _reorderSections(int oldIndex, int newIndex, List<IncomeSectionConfig> sections) async {
    if (!_isEditMode) return;

    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = sections.removeAt(oldIndex);
      sections.insert(newIndex, item);
    });
    await IncomeSectionManager.saveSections(sections);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text('Income Charts',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
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
                  const SnackBar(
                    content: Text('Section order saved'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
      ),
      drawer: DrawerWidget(
        token: widget.token,
        onTransactionChanged: _refreshData,
      ),
      body: FutureBuilder<List<IncomeSectionConfig>>(
        future: _sectionsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sections = snapshot.data!;

          return CustomScrollView(
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
                    child: const Row(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionView(
                token: widget.token,
                onTransactionChanged: _refreshData,
              ),
            ),
          );
          if (result == true) {
            _refreshData();
          }
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}