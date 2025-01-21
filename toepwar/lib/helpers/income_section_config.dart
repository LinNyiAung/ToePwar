import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum IncomeSection {
  distribution,
  monthly,
  daily
}

class IncomeSectionConfig {
  final String name;
  final IncomeSection section;
  bool enabled;

  IncomeSectionConfig({
    required this.name,
    required this.section,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'section': section.toString(),
    'enabled': enabled,
  };

  factory IncomeSectionConfig.fromJson(Map<String, dynamic> json) => IncomeSectionConfig(
    name: json['name'],
    section: IncomeSection.values.firstWhere(
          (e) => e.toString() == json['section'],
    ),
    enabled: json['enabled'],
  );
}

class IncomeSectionManager {
  static const String _prefsKey = 'income_sections';

  static List<IncomeSectionConfig> getDefaultSections() {
    return [
      IncomeSectionConfig(name: 'Income Distribution', section: IncomeSection.distribution),
      IncomeSectionConfig(name: 'Monthly Income', section: IncomeSection.monthly),
      IncomeSectionConfig(name: 'Daily Income', section: IncomeSection.daily),
    ];
  }

  static Future<List<IncomeSectionConfig>> loadSections() async {
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
          .map((data) => IncomeSectionConfig.fromJson(data))
          .toList();
    } catch (e) {
      print('Error loading sections: $e');
      return getDefaultSections();
    }
  }

  static Future<void> saveSections(List<IncomeSectionConfig> sections) async {
    final prefs = await SharedPreferences.getInstance();
    final sectionsJson = json.encode(
      sections.map((section) => section.toJson()).toList(),
    );
    await prefs.setString(_prefsKey, sectionsJson);
  }
}