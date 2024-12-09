import 'package:toepwar/models/transaction_model.dart';

class Dashboard {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final List<Transaction> recentTransactions;

  Dashboard({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.recentTransactions,
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

    List<Transaction> transactions = [];
    if (json['recent_transactions'] != null) {
      try {
        transactions = (json['recent_transactions'] as List)
            .map((transaction) => Transaction.fromJson(transaction))
            .toList();
      } catch (e) {
        print('Error parsing transactions: $e');
      }
    }

    return Dashboard(
      totalIncome: parseDouble(json['income']),
      totalExpense: parseDouble(json['expense']),
      balance: parseDouble(json['balance']),
      recentTransactions: transactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': balance,
      'recent_transactions': recentTransactions
          .map((transaction) => transaction.toJson())
          .toList(),
    };
  }
}