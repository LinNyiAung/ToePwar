import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum ExpenseSection {
  distribution,
  monthly,
  daily
}

class ExpenseSectionConfig {
  final String name;
  final ExpenseSection section;
  bool enabled;

  ExpenseSectionConfig({
    required this.name,
    required this.section,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'section': section.toString(),
    'enabled': enabled,
  };

  factory ExpenseSectionConfig.fromJson(Map<String, dynamic> json) => ExpenseSectionConfig(
    name: json['name'],
    section: ExpenseSection.values.firstWhere(
          (e) => e.toString() == json['section'],
    ),
    enabled: json['enabled'],
  );
}

class ExpenseSectionManager {
  static const String _prefsKey = 'expense_sections';

  static List<ExpenseSectionConfig> getDefaultSections() {
    return [
      ExpenseSectionConfig(name: 'Expense Distribution', section: ExpenseSection.distribution),
      ExpenseSectionConfig(name: 'Monthly Expenses', section: ExpenseSection.monthly),
      ExpenseSectionConfig(name: 'Daily Expenses', section: ExpenseSection.daily),
    ];
  }

  static Future<List<ExpenseSectionConfig>> loadSections() async {
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
          .map((data) => ExpenseSectionConfig.fromJson(data))
          .toList();
    } catch (e) {
      print('Error loading sections: $e');
      return getDefaultSections();
    }
  }

  static Future<void> saveSections(List<ExpenseSectionConfig> sections) async {
    final prefs = await SharedPreferences.getInstance();
    final sectionsJson = json.encode(
      sections.map((section) => section.toJson()).toList(),
    );
    await prefs.setString(_prefsKey, sectionsJson);
  }
}