import 'package:toepwar/models/transaction_model.dart';
import 'package:toepwar/models/goal_model.dart';

class Dashboard {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final List<TransactionModel> recentTransactions;
  final List<Goal> recentGoals;  // Added recentGoals

  Dashboard({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.recentTransactions,
    required this.recentGoals,  // Added recentGoals parameter
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return 0.0;
        }
      }
      return 0.0;
    }

    List<TransactionModel> transactions = [];
    if (json['recent_transactions'] != null) {
      try {
        transactions = (json['recent_transactions'] as List)
            .map((transaction) => TransactionModel.fromJson(transaction))
            .toList();
      } catch (e) {
        print('Error parsing transactions: $e');
      }
    }

    List<Goal> goals = [];
    if (json['recent_goals'] != null) {
      try {
        goals = (json['recent_goals'] as List)
            .map((goal) => Goal.fromJson(goal))
            .toList();
      } catch (e) {
        print('Error parsing goals: $e');
      }
    }

    return Dashboard(
      totalIncome: parseDouble(json['income']),
      totalExpense: parseDouble(json['expense']),
      balance: parseDouble(json['balance']),
      recentTransactions: transactions,
      recentGoals: goals,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': balance,
      'recent_transactions': recentTransactions.map((transaction) => transaction.toJson()).toList(),
      'recent_goals': recentGoals.map((goal) => goal.toJson()).toList(),
    };
  }
}