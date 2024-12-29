import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../helpers/goal_db_helper.dart';
import '../models/goal_model.dart';
import '../utils/api_constants.dart';

class GoalController {
  final String token;
  final GoalDbHelper dbHelper = GoalDbHelper.instance;

  GoalController({required this.token});

  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<List<Goal>> getGoals() async {
    try {
      if (await hasInternetConnection()) {
        final response = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/goals'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> goalsJson = data['goals'];
          final goals = goalsJson.map((json) => Goal.fromJson(json)).toList();

          // Store fetched goals in local database
          await dbHelper.clearAllGoals();
          for (var goal in goals) {
            await dbHelper.insertGoal(goal);
          }
          return goals;
        }
      }

      // If no internet or API call fails, return locally stored goals
      return await dbHelper.getAllGoals();
    } catch (e) {
      // In case of any error, return locally stored goals
      return await dbHelper.getAllGoals();
    }
  }

  Future<Goal> addGoal({
    required String name,
    required double targetAmount,
    required DateTime deadline,
  }) async {
    try {
      if (await hasInternetConnection()) {
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
          final goal = Goal.fromJson(json.decode(response.body));
          await dbHelper.insertGoal(goal);
          return goal;
        }
      }
      throw Exception('Failed to add goal');
    } catch (e) {
      throw Exception('Failed to add goal: $e');
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      if (await hasInternetConnection()) {
        final response = await http.delete(
          Uri.parse('${ApiConstants.baseUrl}/deletegoals/$goalId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          await dbHelper.deleteGoal(goalId);
          return;
        }
      }
      throw Exception('Failed to delete goal');
    } catch (e) {
      throw Exception('Failed to delete goal: $e');
    }
  }

  Future<Goal> updateGoal({
    required String goalId,
    required String name,
    required double targetAmount,
    required DateTime deadline,
  }) async {
    try {
      if (await hasInternetConnection()) {
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
          final goal = Goal.fromJson(json.decode(response.body));
          await dbHelper.updateGoal(goal);
          return goal;
        }
      }
      throw Exception('Failed to update goal');
    } catch (e) {
      throw Exception('Failed to update goal: $e');
    }
  }
}