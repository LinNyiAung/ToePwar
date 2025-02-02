import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/goal_model.dart';
import '../utils/api_constants.dart';

class GoalController {
  final String token;

  GoalController({required this.token});

  Future<List<Goal>> getGoals() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/goals'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> goalsJson = data['goals'];
        return goalsJson.map((json) => Goal.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load goals');
      }
    } catch (e) {
      throw Exception('Failed to get goals: $e');
    }
  }

  Future<Goal> addGoal({
    required String name,
    required double targetAmount,
    required DateTime deadline,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/goal'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'target_amount': targetAmount,
          'current_amount': 0,
          'deadline': deadline.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return Goal.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add goal');
      }
    } catch (e) {
      throw Exception('Failed to add goal: $e');
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/deletegoals/$goalId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete goal');
      }
    } catch (e) {
      throw Exception('Failed to delete goal: $e');
    }
  }

  Future<void> checkGoalReminders() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/checkgoalreminders'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to check goal reminders');
      }
    } catch (e) {
      throw Exception('Failed to check goal reminders: $e');
    }
  }

  Future<Goal> updateGoal({
    required String goalId,
    required String name,
    required double targetAmount,
    required DateTime deadline,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/editgoals/$goalId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'target_amount': targetAmount,
          'deadline': deadline.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return Goal.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update goal');
      }
    } catch (e) {
      throw Exception('Failed to update goal: $e');
    }
  }
}