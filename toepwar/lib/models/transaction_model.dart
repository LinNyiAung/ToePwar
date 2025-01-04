class Transaction {
  final String id;
  final String type;
  final double amount;
  final String category;
  final DateTime date;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Handle both '_id' and 'id' cases
    String transactionId = json['_id']?.toString() ?? json['id']?.toString() ?? '';

    return Transaction(
      id: transactionId,
      type: json['type']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      category: json['category']?.toString() ?? '',
      date: _parseDateTime(json['date']),
    );
  }
}