import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum ReportSection {
  summary,
  incomeCategory,
  expenseCategory,
  goalsProgress,
  balanceTrend
}

class ReportSectionConfig {
  final String name;
  final ReportSection section;
  bool enabled;

  ReportSectionConfig({
    required this.name,
    required this.section,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'section': section.toString(),
    'enabled': enabled,
  };

  factory ReportSectionConfig.fromJson(Map<String, dynamic> json) => ReportSectionConfig(
    name: json['name'],
    section: ReportSection.values.firstWhere(
          (e) => e.toString() == json['section'],
    ),
    enabled: json['enabled'],
  );
}

class ReportSectionManager {
  static const String _prefsKey = 'report_sections';

  static List<ReportSectionConfig> getDefaultSections() {
    return [
      ReportSectionConfig(name: 'Summary', section: ReportSection.summary),
      ReportSectionConfig(name: 'Income by Category', section: ReportSection.incomeCategory),
      ReportSectionConfig(name: 'Expense by Category', section: ReportSection.expenseCategory),
      ReportSectionConfig(name: 'Goals Progress', section: ReportSection.goalsProgress),
      ReportSectionConfig(name: 'Balance Trend', section: ReportSection.balanceTrend),
    ];
  }

  static Future<List<ReportSectionConfig>> loadSections() async {
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
          .map((data) => ReportSectionConfig.fromJson(data))
          .toList();
    } catch (e) {
      print('Error loading sections: $e');
      return getDefaultSections();
    }
  }

  static Future<void> saveSections(List<ReportSectionConfig> sections) async {
    final prefs = await SharedPreferences.getInstance();
    final sectionsJson = json.encode(
      sections.map((section) => section.toJson()).toList(),
    );
    await prefs.setString(_prefsKey, sectionsJson);
  }
}