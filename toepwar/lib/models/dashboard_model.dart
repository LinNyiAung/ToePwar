import 'package:toepwar/models/transaction_model.dart';

class Dashboard {
  final double totalIncome;
  final double totalExpense;

  final List<Transaction> recentTransactions;

  Dashboard({
    required this.totalIncome,
    required this.totalExpense,

    required this.recentTransactions,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse numeric values
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
    print("Dashboard data from JSON: $json");
    // Handle null or empty transactions list
    List<Transaction> transactions = [];
    if (json['recent_transactions'] != null) {
      try {
        transactions = (json['recent_transactions'] as List)
            .map((transaction) => Transaction.fromJson(transaction))
            .toList();
      } catch (e) {
        // If there's an error parsing transactions, return empty list
        print('Error parsing transactions: $e');
      }
    }

    return Dashboard(
      totalIncome: parseDouble(json['income']),
      totalExpense: parseDouble(json['expense']),

      recentTransactions: transactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'income': totalIncome,
      'expense': totalExpense,

      'recent_transactions': recentTransactions
          .map((transaction) => transaction.toJson())
          .toList(),
    };
  }
}