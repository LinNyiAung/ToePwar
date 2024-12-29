import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/dashboard_model.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';

class DashboardDbHelper {
  static final DashboardDbHelper instance = DashboardDbHelper._init();
  static Database? _database;

  DashboardDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dashboard.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Dashboard summary table
    await db.execute('''
      CREATE TABLE dashboard_summary(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_income REAL NOT NULL,
        total_expense REAL NOT NULL,
        balance REAL NOT NULL,
        last_updated TEXT NOT NULL
      )
    ''');

    // Recent goals table
    await db.execute('''
      CREATE TABLE recent_goals(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL,
        deadline TEXT NOT NULL,
        completed INTEGER NOT NULL,
        progress REAL NOT NULL,
        completion_date TEXT
      )
    ''');
  }

  // Save dashboard summary
  Future<void> saveDashboardSummary(Dashboard dashboard) async {
    final db = await database;

    // Clear existing summary
    await db.delete('dashboard_summary');

    // Insert new summary
    await db.insert('dashboard_summary', {
      'total_income': dashboard.totalIncome,
      'total_expense': dashboard.totalExpense,
      'balance': dashboard.balance,
      'last_updated': DateTime.now().toIso8601String(),
    });

    // Update recent goals
    await db.delete('recent_goals');
    for (var goal in dashboard.recentGoals) {
      await db.insert('recent_goals', {
        'id': goal.id,
        'name': goal.name,
        'target_amount': goal.targetAmount,
        'current_amount': goal.currentAmount,
        'deadline': goal.deadline.toIso8601String(),
        'completed': goal.completed ? 1 : 0,
        'progress': goal.progress,
        'completion_date': goal.completionDate?.toIso8601String(),
      });
    }
  }

  Future<Dashboard?> getDashboardData() async {
    final db = await database;

    // Get summary
    final summaryList = await db.query('dashboard_summary');
    if (summaryList.isEmpty) return null;

    final summary = summaryList.first;

    // Get recent goals
    final goalsData = await db.query('recent_goals');
    final goals = goalsData.map((data) {
      return Goal(
        id: data['id'] as String,
        name: data['name'] as String,
        targetAmount: data['target_amount'] as double,
        currentAmount: data['current_amount'] as double,
        deadline: DateTime.parse(data['deadline'] as String),
        completed: data['completed'] == 1,
        completionDate: data['completion_date'] != null
            ? DateTime.parse(data['completion_date'] as String)
            : null,
      );
    }).toList();

    return Dashboard(
      totalIncome: summary['total_income'] as double,
      totalExpense: summary['total_expense'] as double,
      balance: summary['balance'] as double,
      recentTransactions: [], // Will be filled by TransactionDbHelper
      recentGoals: goals,
    );
  }

  Future<void> clearDashboardData() async {
    final db = await database;
    await db.delete('dashboard_summary');
    await db.delete('recent_goals');
  }
}