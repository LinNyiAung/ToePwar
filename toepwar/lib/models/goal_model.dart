class Goal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final bool completed;
  final DateTime? completionDate;
  final double progress;

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    this.completed = false,
    this.completionDate,
  }) : progress = (currentAmount / targetAmount) * 100;

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      targetAmount: _parseDouble(json['target_amount']),
      currentAmount: _parseDouble(json['current_amount']),
      deadline: _parseDateTime(json['deadline']),
      completed: json['completed'] ?? false,
      completionDate: json['completion_date'] != null
          ? _parseDateTime(json['completion_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline.toIso8601String(),
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}