class ApiConstants {
  static const String baseUrl = 'http://192.168.1.3:800';

  // Add other API-related constants here
  static final Map<String, Map<String, List<String>>> nestedTransactionCategories = {
    'income': {
      'Professional Income': [
        'Salary',
        'Freelance Work',
        'Bonus',
        'Commission'
      ],
      'Passive Income': [
        'Investment',
        'Rental Income',
        'Dividends',
        'Interest'
      ],
      'Other Income': [
        'Gift',
        'Refund',
        'Inheritance'
      ]
    },
    'expense': {
      'Living Expenses': [
        'Rent/Mortgage',
        'Utilities',
        'Groceries',
        'Dining Out',
        'Home Maintenance'
      ],
      'Transportation': [
        'Fuel',
        'Car Maintenance',
        'Public Transit',
        'Taxi'
      ],
      'Personal': [
        'Clothing',
        'Healthcare',
        'Fitness',
        'Personal Care'
      ],
      'Entertainment': [
        'Streaming Services',
        'Movies/Concerts',
        'Hobbies',
        'Subscriptions'
      ],
      'Financial': [
        'Taxes',
        'Insurance',
        'Debt Repayment',
        'Bank Fees'
      ],
      'Education': [
        'Courses',
        'Books',
        'Online Learning'
      ],
      'Gifts & Donations': [
        'Gifts',
        'Charity'
      ],
      'Miscellaneous': [
        'Travel',
        'Electronics',
        'Other Expenses'
      ]
    }
  };
}
