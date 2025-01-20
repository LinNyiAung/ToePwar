import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum DashboardSection {
  recentTransactions,
  recentGoals,
  balanceTrend,
  expenseStructure,
  incomeStructure
}

class SectionConfig {
  final String name;
  final DashboardSection section;
  bool enabled;

  SectionConfig({
    required this.name,
    required this.section,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'section': section.toString(),
    'enabled': enabled,
  };

  factory SectionConfig.fromJson(Map<String, dynamic> json) => SectionConfig(
    name: json['name'],
    section: DashboardSection.values.firstWhere(
          (e) => e.toString() == json['section'],
    ),
    enabled: json['enabled'],
  );
}

class DashboardSectionManager {
  static const String _prefsKey = 'dashboard_sections';

  static List<SectionConfig> getDefaultSections() {
    return [
      SectionConfig(name: 'Recent Transactions', section: DashboardSection.recentTransactions),
      SectionConfig(name: 'Recent Goals', section: DashboardSection.recentGoals),
      SectionConfig(name: 'Balance Trend', section: DashboardSection.balanceTrend),
      SectionConfig(name: 'Expense Structure', section: DashboardSection.expenseStructure),
      SectionConfig(name: 'Income Structure', section: DashboardSection.incomeStructure),
    ];
  }

  static Future<List<SectionConfig>> loadSections() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sectionsJson = prefs.getString(_prefsKey);

    if (sectionsJson == null) {
      final defaultSections = getDefaultSections();
      await saveSections(defaultSections);
      return defaultSections;
    }

    try {
      final List<dynamic> sectionsData = json.decode(sectionsJson);
      return sectionsData
          .map((data) => SectionConfig.fromJson(data))
          .toList();
    } catch (e) {
      print('Error loading sections: $e');
      return getDefaultSections();
    }
  }

  static Future<void> saveSections(List<SectionConfig> sections) async {
    final prefs = await SharedPreferences.getInstance();
    final sectionsJson = json.encode(
      sections.map((section) => section.toJson()).toList(),
    );
    await prefs.setString(_prefsKey, sectionsJson);
  }
}