import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/notification_service.dart';
import '../models/dashboard_model.dart';
import '../models/goal_model.dart';
import '../models/notification_model.dart';
import '../models/transaction_model.dart';
import '../utils/api_constants.dart';

class DashboardController {
  final String token;

  DashboardController({required this.token});

  Future<Dashboard> getDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/dashboard'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final dashboardData = json.decode(response.body);

        // Check if there's a notification in the response
        if (dashboardData['notification'] != null) {
          final notification = AppNotification.fromJson(dashboardData['notification']);
          await NotificationService.instance.showBalanceAlert(notification);
        }

        // Fetch recent goals separately and combine with dashboard data
        final recentGoals = await getRecentGoals();
        dashboardData['recent_goals'] = recentGoals.map((g) => g.toJson()).toList();
        return Dashboard.fromJson(dashboardData);
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } catch (e) {
      throw Exception('Failed to get dashboard data: $e');
    }
  }


  Future<List<Goal>> getRecentGoals() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/goals'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> goalsJson = data['goals'];
        return goalsJson
            .map((json) => Goal.fromJson(json))
            .take(3)  // Only take the 3 most recent goals
            .toList();
      } else {
        throw Exception('Failed to load goals');
      }
    } catch (e) {
      throw Exception('Failed to get goals: $e');
    }
  }

  Future<List<Transaction>> getRecentTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/gettransactions'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> transactionsJson = json.decode(response.body);

        // Limit to 5 recent transactions
        return transactionsJson
            .map((json) => Transaction.fromJson(json))
            .take(5)
            .toList();
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  
}
