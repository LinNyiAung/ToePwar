import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Add LocalizationsDelegate
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)
        ?? AppLocalizations(const Locale('en')); // Provide fallback
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Existing translations
      'dashboard': 'Dashboard',
      'profile': 'Profile',
      'financialOverview': 'Financial Overview',
      'income': 'Income',
      'expense': 'Expense',
      'balance': 'Balance',
      'recentTransactions': 'Recent Transactions',
      'recentGoals': 'Recent Goals',
      'seeAll': 'See All',
      'noRecentTransactions': 'No recent transactions',
      'noActiveGoals': 'No active goals',
      'editProfile': 'Edit Profile',
      'selectLanguage': 'Select Language',
      'language': 'Language',
      'notifications': 'Notifications',
      'security': 'Security',
      'helpSupport': 'Help & Support',
      'about': 'About',
      'logout': 'Logout',
      'confirmLogout': 'Confirm Logout',
      'logoutMessage': 'Are you sure you want to logout?',
      'cancel': 'Cancel',

      // New translations for Dashboard
      'retry': 'Retry',
      'error': 'Error',
      'dragSectionsToReorder': 'Drag sections to reorder',
      'sectionOrderSaved': 'Section order saved',
      'totalIncome': 'Total Income',
      'totalExpense': 'Total Expense',
      'netIncome': 'Net Income',

      // Financial Report translations
      'financialReport': 'Financial Report',
      'exportAsExcel': 'Export as Excel',
      'exportAsPDF': 'Export as PDF',
      'resetToAllTime': 'Reset to all-time view',
      'noDataAvailable': 'No data available',
      'refresh': 'Refresh',
      'incomeByCategoryTitle': 'Income by Category',
      'expenseByCategoryTitle': 'Expense by Category',
      'savingsGoals': 'Savings Goals',
      'completed': 'Completed',
      'progress': 'Progress',
      'of': 'of',
      'errorLoadingReport': 'Error loading report',
      'errorExportingReport': 'Error exporting report',
      'errorExportingPDF': 'Error exporting PDF report',

      // Budget Plan View translations
      'aiBudgetPlan': 'AI Budget Plan',
      'noBudgetPlan': 'No budget plan available',
      'budgetPeriod': 'Budget Period',
      'totalBudget': 'Total Budget',
      'savingsTarget': 'Savings Target',
      'period': 'Period',
      'categoryBudgets': 'Category Budgets',
      'aiRecommendations': 'AI Recommendations',

      // Financial Forecast View translations
      'financialForecast': 'Financial Forecast',
      'forecastPeriod': 'Forecast Period',
      'months': 'months',
      'monthRange': '(1-24 months)',
      'forecastTrends': 'Forecast Trends',
      'categoryForecasts': 'Category Forecasts',
      'incomeCategories': 'Income Categories',
      'expenseCategories': 'Expense Categories',
      'goalProjections': 'Goal Projections',
      'financialInsights': 'Financial Insights',
      'riskLevel': 'Risk',
      'actionItems': 'Action Items',
      'growthOpportunities': 'Growth Opportunities',
      'projectedIncome': 'Projected Income',
      'projectedExpenses': 'Projected Expenses',
      'projectedSavings': 'Projected Savings',
      'monthlyRequired': 'Monthly Required',
      'probability': 'Probability',

      // Goals View translations
      'financialGoals': 'Financial Goals',
      'noSavingGoals': 'No saving goals yet',
      'addNewGoal': 'Add New Saving Goal',
      'editGoal': 'Edit Saving Goal',
      'deleteGoal': 'Delete Goal',
      'deleteGoalConfirm': 'Are you sure you want to delete "{name}"?',
      'goalName': 'Goal Name',
      'targetAmount': 'Target Amount',
      'selectDeadline': 'Select Deadline',
      'deadline': 'Deadline',

      'pleaseFilAllFields': 'Please fill all fields',
      'goalDeletedSuccess': 'Goal deleted successfully',
      'goalUpdatedSuccess': 'Goal updated successfully',
      'currentAmount': 'Current Amount',


      // Add Transaction View translations
      'addTransaction': 'Add Transaction',
      'quickInput': 'Quick Input',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'voiceInput': 'Voice Input',
      'listening': 'Listening...',
      'voiceInputGuide': 'Voice Input Guide',
      'sentenceStructure': 'Sentence Structure',
      'examplePhrases': 'Example Phrases',
      'tips': 'Tips',
      'speakClearly': '• Speak clearly and at a normal pace',
      'includeAmountCategory': '• Include the amount and category',
      'waitForIndicator': '• Wait for the blue microphone indicator',
      'editAfterVoice': '• You can edit details after voice input',
      'transactionType': 'Transaction Type',
      'transactionDetails': 'Transaction Details',
      'amount': 'Amount',
      'category': 'Category',
      'subcategory': 'Subcategory',
      'scanReceiptError': 'Error scanning receipt: {error}',
      'couldNotExtractAmount': 'Could not extract amount from receipt',
      'couldNotUnderstandVoice': 'Could not understand voice input. Please try again.',
      'voiceInputError': 'Error processing voice input: {error}',


      // Transaction History View
      'transactionHistory': 'Transaction History',
      'noTransactions': 'No transactions found',
      'noMatchingTransactions': 'No transactions match the filter',
      'filterTransactions': 'Filter Transactions',
      'selectMainCategory': 'Select Main Category',
      'selectSubCategory': 'Select Subcategory',
      'allDates': 'All dates',
      'resetFilter': 'Reset',
      'applyFilter': 'Apply',
      'type': 'Type',
      'mainCategory': 'Main Category',
      'subCategory': 'Subcategory',
      'dateRange': 'Date Range',
      'all': 'All',

      // Edit Transaction View
      'editTransaction': 'Edit Transaction',
      'quickUpdate': 'Quick Update',

      'amountCategoryDate': '[Amount] + [Category] + [Date]',
      'examplePhrasesHeader': 'Example Phrases:',
      'speakingTips': 'Speaking Tips:',
      'updateTransaction': 'Update Transaction',
      'transactionUpdated': 'Transaction updated successfully',
      'errorUpdatingTransaction': 'Error updating transaction',

      // Drawer Labels
      'transactions': 'Transactions',
      'analytics': 'Analytics',
      'expenseAnalysis': 'Expense Analysis',
      'incomeAnalysis': 'Income Analysis',
      'report': 'Report',
      'planning': 'Planning',
      'aiForecast': 'AI Forecasting',
      'aiPlanning': 'AI Planning',


      // Expense Structure View
      'expenseCharts': 'Expense Charts',

      'dragToReorder': 'Drag sections to reorder',

      // Daily Expense Chart
      'dailyExpenses': 'Daily Expenses',
      'selectMonth': 'Select Month',
      'monthlyTotal': 'Monthly Total',
      'dailyAverage': 'Daily Average',
      'noExpenseData': 'No expense data available for selected month',

      // Monthly Expense Chart
      'monthlyExpenses': 'Monthly Expenses',
      'selectYear': 'Select Year',
      'yearlyTotal': 'Yearly Total',
      'monthlyAverage': 'Monthly Average',
      'noMonthlyData': 'No expense data available for selected year',

      // Expense Distribution (Pie Chart)
      'expenseDistribution': 'Expense Distribution',
      'allTime': 'All Time',
      'selectDateRange': 'Select Date Range',
      'clearDateFilter': 'Clear Date Filter',
      'noDistributionData': 'No expense data available for selected period',

      // Balance Trend Chart
      'balanceTrend': 'Balance Trend',
      'daily': 'Daily',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      'lowest': 'Lowest',
      'highest': 'Highest',
      'current': 'Current',
      'noBalanceData': 'No balance data available for selected period',

      // Common Chart Elements
      'loading': 'Loading',

      'failedToLoad': 'Failed to load data',


      // Income Structure View
      'incomeCharts': 'Income Charts',
      'dailyIncome': 'Daily Income',
      'monthlyIncome': 'Monthly Income',
      'incomeDistribution': 'Income Distribution',

      'noIncomeData': 'No income data available',
      'noIncomeDataYear': 'No income data available for selected year',
      'noIncomeDataMonth': 'No income data available for selected month',
      'noIncomeDataPeriod': 'No income data available for selected period',

      'editMode': 'Edit Mode',
      'saveOrder': 'Save Order',

    },
    'my': {
      // Existing translations
      'dashboard': 'ဒက်ရှ်ဘုတ်',
      'profile': 'ပရိုဖိုင်',
      'financialOverview': 'ငွေကြေးခြုံငုံသုံးသပ်ချက်',
      'income': 'ဝင်ငွေ',
      'expense': 'အသုံးစရိတ်',
      'balance': 'လက်ကျန်',
      'recentTransactions': 'လက်တလော ငွေဝင်/ထွက်များ',
      'recentGoals': 'လက်တလော ငွေကြေးရည်မှန်းချက်‌များ',
      'seeAll': 'အားလုံး',
      'noRecentTransactions': 'မကြာသေးမီက ငွေဝင်/ထွက်များ မရှိပါ',
      'noActiveGoals': 'ငွေကြေးရည်မှန်းချက် မရှိပါ',
      'editProfile': 'ပရိုဖိုင်ပြင်ဆင်ရန်',
      'notifications': 'အကြောင်းကြားချက်များ',
      'language': 'ဘာသာစကား',
      'selectLanguage': 'ဘာသာစကားရွေးပါ',
      'security': 'လုံခြုံရေး',
      'helpSupport': 'အကူအညီနှင့် ပံ့ပိုးမှု',
      'about': 'အကြောင်း',
      'logout': 'ထွက်ရန်',
      'confirmLogout': 'ထွက်ရန် အတည်ပြုပါ',
      'logoutMessage': 'သင် ထွက်လိုသည်မှာ သေချာပါသလား?',
      'cancel': 'ပယ်ဖျက်ရန်',

      // New translations for Dashboard
      'retry': 'ပြန်လည်ကြိုးစားရန်',
      'error': 'အမှား',
      'dragSectionsToReorder': 'အပိုင်းများကို ပြန်လည်စီစဉ်ရန် ဆွဲယူပါ',
      'sectionOrderSaved': 'အပိုင်းအစဉ်ကို သိမ်းဆည်းပြီးပါပြီ',
      'totalIncome': 'စုစုပေါင်းဝင်ငွေ',
      'totalExpense': 'စုစုပေါင်းအသုံးစရိတ်',
      'netIncome': 'အသားတင်ဝင်ငွေ',

      // Financial Report translations
      'financialReport': 'ငွေကြေးအစီရင်ခံစာ',
      'exportAsExcel': 'Excel အဖြစ်ထုတ်ယူရန်',
      'exportAsPDF': 'PDF အဖြစ်ထုတ်ယူရန်',
      'resetToAllTime': 'အချိန်အားလုံးသို့ ပြန်လည်သတ်မှတ်ရန်',
      'noDataAvailable': 'အချက်အလက် မရရှိနိုင်ပါ',
      'refresh': 'ပြန်လည်စတင်ရန်',
      'incomeByCategoryTitle': 'အမျိုးအစားအလိုက် ဝင်ငွေ',
      'expenseByCategoryTitle': 'အမျိုးအစားအလိုက် အသုံးစရိတ်',
      'savingsGoals': 'ငွေကြေးရည်မှန်းချက်‌များ',
      'completed': 'ပြီးဆုံးပါပြီ',
      'progress': 'တိုးတက်မှု',
      'of': '၏',
      'errorLoadingReport': 'အစီရင်ခံစာ ဖတ်ယူရာတွင် အမှားရှိနေပါသည်',
      'errorExportingReport': 'အစီရင်ခံစာ ထုတ်ယူရာတွင် အမှားရှိနေပါသည်',
      'errorExportingPDF': 'PDF အစီရင်ခံစာ ထုတ်ယူရာတွင် အမှားရှိနေပါသည်',

      // Budget Plan View translations
      'aiBudgetPlan': 'AI ဘတ်ဂျက်စီမံကိန်း',
      'noBudgetPlan': 'ဘတ်ဂျက်စီမံကိန်း မရှိသေးပါ',
      'budgetPeriod': 'ဘတ်ဂျက်ကာလ',
      'totalBudget': 'စုစုပေါင်းဘတ်ဂျက်',
      'savingsTarget': 'စုဆောင်းငွေပန်းတိုင်',
      'period': 'ကာလ',
      'categoryBudgets': 'အမျိုးအစားအလိုက် ဘတ်ဂျက်များ',
      'aiRecommendations': 'AI အကြံပြုချက်များ',

      // Financial Forecast View translations
      'financialForecast': 'AI ငွေကြေးခန့်မှန်းချက်',
      'forecastPeriod': 'ခန့်မှန်းကာလ',
      'months': 'လများ',
      'monthRange': '(၁-၂၄ လ)',
      'forecastTrends': 'ခန့်မှန်းချက်လမ်းကြောင်းများ',
      'categoryForecasts': 'အမျိုးအစားအလိုက် ခန့်မှန်းချက်များ',
      'incomeCategories': 'ဝင်ငွေအမျိုးအစားများ',
      'expenseCategories': 'အသုံးစရိတ်အမျိုးအစားများ',
      'goalProjections': 'ငွေကြေးရည်မှန်းချက်ခန့်မှန်းချက်များ',
      'financialInsights': 'ငွေကြေးသုံးသပ်ချက်များ',
      'riskLevel': 'အန္တရာယ်',
      'actionItems': 'လုပ်ဆောင်ရန်များ',
      'growthOpportunities': 'တိုးတက်မှုအခွင့်အလမ်းများ',
      'projectedIncome': 'ခန့်မှန်းဝင်ငွေ',
      'projectedExpenses': 'ခန့်မှန်းအသုံးစရိတ်',
      'projectedSavings': 'ခန့်မှန်းစုဆောင်းငွေ',
      'monthlyRequired': 'လစဉ်လိုအပ်ငွေ',
      'probability': 'ဖြစ်နိုင်ခြေ',

      // Goals View translations
      'financialGoals': 'ငွေကြေးရည်မှန်းချက်‌များ',
      'noSavingGoals': 'ငွေကြေးရည်မှန်းချက်‌များ မရှိသေးပါ',
      'addNewGoal': 'ငွေကြေးရည်မှန်းချက်‌အသစ် ထည့်ရန်',
      'editGoal': 'ငွေကြေးရည်မှန်းချက်‌ ပြင်ဆင်ရန်',
      'deleteGoal': 'ငွေကြေးရည်မှန်းချက်‌ဖျက်ရန်',
      'deleteGoalConfirm': '"{name}" ကို ဖျက်မှာ သေချာပါသလား?',
      'goalName': 'ငွေကြေးရည်မှန်းချက်‌အမည်',
      'targetAmount': 'ငွေပမာဏ',
      'selectDeadline': 'သတ်မှတ်ရက် ရွေးရန်',
      'deadline': 'သတ်မှတ်ရက်',

      'pleaseFilAllFields': 'ကျေးဇူးပြု၍ အချက်အလက်အားလုံး ဖြည့်ပါ',
      'goalDeletedSuccess': 'ငွေကြေးရည်မှန်းချက်ကို အောင်မြင်စွာ ဖျက်ပြီးပါပြီ',
      'goalUpdatedSuccess': 'ငွေကြေးရည်မှန်းချက်ကို အောင်မြင်စွာ မွမ်းမံပြီးပါပြီ',
      'currentAmount': 'လက်ရှိပမာဏ',


      // Add Transaction View translations
      'addTransaction': 'ငွေဝင်/ထွက် ထည့်ရန်',
      'quickInput': 'အမြန်ထည့်သွင်းရန်',
      'camera': 'ကင်မရာ',
      'gallery': 'ဓာတ်ပုံပြခန်း',
      'voiceInput': 'အသံဖြင့်ထည့်သွင်းရန်',
      'listening': 'နားထောင်နေသည်...',
      'voiceInputGuide': 'အသံဖြင့်ထည့်သွင်းရန် လမ်းညွှန်',
      'sentenceStructure': 'ဝါကျဖွဲ့စည်းပုံ: ',
      'examplePhrases': 'နမူနာဝါကျများ: ',
      'tips': 'အကြံပြုချက်များ: ',
      'speakClearly': '• ရှင်းရှင်းလင်းလင်း ပုံမှန်အမြန်နှုန်းဖြင့် ပြောပါ',
      'includeAmountCategory': '• ပမာဏနှင့် အမျိုးအစားကို ထည့်သွင်းပါ',
      'waitForIndicator': '• အပြာရောင်မိုက်ခရိုဖုန်း အချက်ပြမှုကို စောင့်ပါ',
      'editAfterVoice': '• အသံဖြင့်ထည့်သွင်းပြီးနောက် ပြင်ဆင်နိုင်ပါသည်',
      'transactionType': 'ငွေအမျိုးအစား',
      'transactionDetails': 'ငွေဝင်/ထွက်အသေးစိတ်',
      'amount': 'ပမာဏ',
      'category': 'အမျိုးအစား',
      'subcategory': 'အမျိုးအစားခွဲ',
      'scanReceiptError': 'ပြေစာစကင်ဖတ်ရာတွင် အမှား: {error}',
      'couldNotExtractAmount': 'ပြေစာမှ ပမာဏကို မထုတ်ယူနိုင်ပါ',
      'couldNotUnderstandVoice': 'အသံထည့်သွင်းမှုကို နားမလည်ပါ။ ထပ်မံကြိုးစားပါ။',
      'voiceInputError': 'အသံထည့်သွင်းမှု ပြုလုပ်ရာတွင် အမှား: {error}',


      // Transaction History View
      'transactionHistory': 'ငွေစာရင်းမှတ်တမ်း',
      'noTransactions': 'ငွေဝင်/ထွက်များ မရှိသေးပါ',
      'noMatchingTransactions': 'စစ်ထုတ်ထားသော ငွေဝင်/ထွက်များ မရှိပါ',
      'filterTransactions': 'ငွေဝင်/ထွက်များကို စစ်ထုတ်ရန်',
      'selectMainCategory': 'အဓိကအမျိုးအစား ရွေးချယ်ပါ',
      'selectSubCategory': 'အမျိုးအစားခွဲ ရွေးချယ်ပါ',
      'allDates': 'ရက်စွဲအားလုံး',
      'resetFilter': 'ပြန်လည်သတ်မှတ်ရန်',
      'applyFilter': 'အသုံးပြုရန်',
      'type': 'အမျိုးအစား',
      'mainCategory': 'အဓိကအမျိုးအစား',
      'subCategory': 'အမျိုးအစားခွဲ',
      'dateRange': 'ရက်စွဲအပိုင်းအခြား',
      'all': 'အားလုံး',

      // Edit Transaction View
      'editTransaction': 'ငွေဝင်/ထွက် ပြင်ဆင်ရန်',
      'quickUpdate': 'အမြန်ပြင်ဆင်ရန်',

      'amountCategoryDate': '[ပမာဏ] + [အမျိုးအစား] + [ရက်စွဲ]',

      'speakingTips': 'ပြောဆိုရန် အကြံပြုချက်များ:',
      'updateTransaction': 'ငွေဝင်/ထွက် ပြင်ဆင်ရန်',
      'transactionUpdated': 'ငွေဝင်/ထွက်ကို အောင်မြင်စွာ ပြင်ဆင်ပြီးပါပြီ',
      'errorUpdatingTransaction': 'ငွေဝင်/ထွက် ပြင်ဆင်ရာတွင် အမှားရှိနေပါသည်',

      // Drawer Labels
      'transactions': 'ငွေဝင်/ထွက်များ',
      'analytics': 'လေ့လာစိစစ်ချက်များ',
      'expenseAnalysis': 'အသုံးစရိတ် လေ့လာစိစစ်ချက်',
      'incomeAnalysis': 'ဝင်ငွေ လေ့လာစိစစ်ချက်',
      'report': 'အစီရင်ခံစာ',
      'planning': 'စီမံကိန်း',
      'aiForecast': 'AI ခန့်မှန်းချက်',
      'aiPlanning': 'AI စီမံကိန်း',


      // Expense Structure View
      'expenseCharts': 'အသုံးစရိတ်ဇယားများ',



      // Daily Expense Chart
      'dailyExpenses': 'နေ့စဉ်အသုံးစရိတ်များ',
      'selectMonth': 'လရွေးပါ',
      'monthlyTotal': 'လစဉ်စုစုပေါင်း',
      'dailyAverage': 'နေ့စဉ်ပျမ်းမျှ',
      'noExpenseData': 'ရွေးချယ်ထားသောလအတွက် အသုံးစရိတ်အချက်အလက် မရှိပါ',

      // Monthly Expense Chart
      'monthlyExpenses': 'လစဉ်အသုံးစရိတ်များ',
      'selectYear': 'နှစ်ရွေးပါ',
      'yearlyTotal': 'နှစ်စဉ်စုစုပေါင်း',
      'monthlyAverage': 'လစဉ်ပျမ်းမျှ',
      'noMonthlyData': 'ရွေးချယ်ထားသောနှစ်အတွက် အသုံးစရိတ်အချက်အလက် မရှိပါ',

      // Expense Distribution (Pie Chart)
      'expenseDistribution': 'အသုံးစရိတ်ခွဲဝေမှု',
      'allTime': 'အချိန်အားလုံး',
      'selectDateRange': 'ရက်စွဲအပိုင်းအခြားရွေးပါ',
      'clearDateFilter': 'ရက်စွဲစစ်ထုတ်မှုကို ရှင်းလင်းရန်',
      'noDistributionData': 'ရွေးချယ်ထားသောကာလအတွက် အသုံးစရိတ်အချက်အလက် မရှိပါ',

      // Balance Trend Chart
      'balanceTrend': 'လက်ကျန်ငွေ အလားအလာ',
      'daily': 'နေ့စဉ်',
      'monthly': 'လစဉ်',
      'yearly': 'နှစ်စဉ်',
      'lowest': 'အနိမ့်ဆုံး',
      'highest': 'အမြင့်ဆုံး',
      'current': 'လက်ရှိ',
      'noBalanceData': 'ရွေးချယ်ထားသောကာလအတွက် လက်ကျန်ငွေအချက်အလက် မရှိပါ',

      // Common Chart Elements
      'loading': 'ဖွင့်နေသည်',

      'failedToLoad': 'ဒေတာတင်ရန် မအောင်မြင်ပါ',

      // Income Structure View
      'incomeCharts': 'ဝင်ငွေဇယားများ',
      'dailyIncome': 'နေ့စဉ်ဝင်ငွေ',
      'monthlyIncome': 'လစဉ်ဝင်ငွေ',
      'incomeDistribution': 'ဝင်ငွေခွဲဝေမှု',

      'noIncomeData': 'ဝင်ငွေအချက်အလက် မရှိသေးပါ',
      'noIncomeDataYear': 'ရွေးချယ်ထားသောနှစ်အတွက် ဝင်ငွေအချက်အလက် မရှိပါ',
      'noIncomeDataMonth': 'ရွေးချယ်ထားသောလအတွက် ဝင်ငွေအချက်အလက် မရှိပါ',
      'noIncomeDataPeriod': 'ရွေးချယ်ထားသောကာလအတွက် ဝင်ငွေအချက်အလက် မရှိပါ',

      'editMode': 'ပြင်ဆင်ရန်မုဒ်',
      'saveOrder': 'အစီအစဉ်သိမ်းရန်',

    },
  };

  String get currentLanguage => locale.languageCode;

  String translate(String key) {
    return _localizedValues[currentLanguage]?[key] ??
        _localizedValues['en']?[key] ??
        key; // Fallback to key if translation not found
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'my'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}