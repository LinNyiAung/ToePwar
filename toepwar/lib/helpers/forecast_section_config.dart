import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum ForecastSection {
  timeRange,
  summary,
  forecastTrend,
  categoryForecasts,
  insights,
  goalProjections
}

class ForecastSectionConfig {
  final String name;
  final ForecastSection section;
  bool enabled;

  ForecastSectionConfig({
    required this.name,
    required this.section,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'section': section.toString(),
    'enabled': enabled,
  };

  factory ForecastSectionConfig.fromJson(Map<String, dynamic> json) => ForecastSectionConfig(
    name: json['name'],
    section: ForecastSection.values.firstWhere(
          (e) => e.toString() == json['section'],
    ),
    enabled: json['enabled'],
  );
}

class ForecastSectionManager {
  static const String _prefsKey = 'forecast_sections';

  static List<ForecastSectionConfig> getDefaultSections() {
    return [
      ForecastSectionConfig(name: 'Forecast Period', section: ForecastSection.timeRange),
      ForecastSectionConfig(name: 'Summary', section: ForecastSection.summary),
      ForecastSectionConfig(name: 'Forecast Trend', section: ForecastSection.forecastTrend),
      ForecastSectionConfig(name: 'Category Forecasts', section: ForecastSection.categoryForecasts),
      ForecastSectionConfig(name: 'Insights', section: ForecastSection.insights),
      ForecastSectionConfig(name: 'Goal Projections', section: ForecastSection.goalProjections),
    ];
  }

  static Future<List<ForecastSectionConfig>> loadSections() async {
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
          .map((data) => ForecastSectionConfig.fromJson(data))
          .toList();
    } catch (e) {
      print('Error loading sections: $e');
      return getDefaultSections();
    }
  }

  static Future<void> saveSections(List<ForecastSectionConfig> sections) async {
    final prefs = await SharedPreferences.getInstance();
    final sectionsJson = json.encode(
      sections.map((section) => section.toJson()).toList(),
    );
    await prefs.setString(_prefsKey, sectionsJson);
  }
}