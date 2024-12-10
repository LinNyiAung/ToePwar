class ApiConstants {
  static const String baseUrl = 'http://192.168.21.32:800';

  // Add other API-related constants here
  static const Map<String, List<String>> transactionCategories = {
    'income': ['Salary', 'Business', 'Investment', 'Gift', 'Other'],
    'expense': ['Shopping', 'Food', 'Transportation', 'Bills', 'Other'],
  };
}
