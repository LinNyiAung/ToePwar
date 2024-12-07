import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_model.dart';
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
        print('DFashboard api response: ${response.body}');
        return Dashboard.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } catch (e) {
      throw Exception('Failed to get dashboard data: $e');
    }
  }

  Future<List<Transaction>> getRecentTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/transactions'),
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
