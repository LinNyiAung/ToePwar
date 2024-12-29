import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/dashboard_db_helper.dart';
import '../helpers/transaction_db_helper.dart';
import '../models/dashboard_model.dart';
import '../models/goal_model.dart';
import '../models/transaction_model.dart';
import '../utils/api_constants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


class DashboardController {
  final String token;
  final DashboardDbHelper dbHelper = DashboardDbHelper.instance;
  final TransactionDbHelper transactionDbHelper = TransactionDbHelper.instance;

  DashboardController({required this.token});

  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<Dashboard> getDashboardData() async {
    try {
      if (await hasInternetConnection()) {
        // Try to fetch from API
        final response = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/dashboard'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final dashboardData = json.decode(response.body);
          // Fetch recent goals and combine with dashboard data
          final recentGoals = await getRecentGoals();
          dashboardData['recent_goals'] = recentGoals.map((g) => g.toJson()).toList();

          final dashboard = Dashboard.fromJson(dashboardData);
          // Save to local database
          await dbHelper.saveDashboardSummary(dashboard);
          return dashboard;
        }
      }

      // If offline or API call failed, get from local database
      final localDashboard = await dbHelper.getDashboardData();
      if (localDashboard != null) {
        // Get recent transactions from local database
        final recentTransactions = await transactionDbHelper.getAllTransactions();
        return Dashboard(
          totalIncome: localDashboard.totalIncome,
          totalExpense: localDashboard.totalExpense,
          balance: localDashboard.balance,
          recentTransactions: recentTransactions.take(5).toList(),
          recentGoals: localDashboard.recentGoals,
        );
      }

      throw Exception('No dashboard data available');
    } catch (e) {
      // Try to get local data as fallback
      final localDashboard = await dbHelper.getDashboardData();
      if (localDashboard != null) {
        final recentTransactions = await transactionDbHelper.getAllTransactions();
        return Dashboard(
          totalIncome: localDashboard.totalIncome,
          totalExpense: localDashboard.totalExpense,
          balance: localDashboard.balance,
          recentTransactions: recentTransactions.take(5).toList(),
          recentGoals: localDashboard.recentGoals,
        );
      }
      throw Exception('Failed to get dashboard data: $e');
    }
  }

  Future<List<Goal>> getRecentGoals() async {
    try {
      if (await hasInternetConnection()) {
        final response = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/goals'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> goalsJson = data['goals'];
          return goalsJson
              .map((json) => Goal.fromJson(json))
              .take(3)
              .toList();
        }
      }

      // If offline or API call failed, get goals from dashboard data
      final localDashboard = await dbHelper.getDashboardData();
      if (localDashboard != null) {
        return localDashboard.recentGoals;
      }
      return [];
    } catch (e) {
      // Try to get local goals as fallback
      final localDashboard = await dbHelper.getDashboardData();
      if (localDashboard != null) {
        return localDashboard.recentGoals;
      }
      return [];
    }
  }

  Future<List<TransactionModel>> getRecentTransactions() async {
    try {
      final transactions = await transactionDbHelper.getAllTransactions();
      return transactions.take(5).toList();
    } catch (e) {
      throw Exception('Failed to get recent transactions: $e');
    }
  }
}
