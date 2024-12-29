import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/goal_model.dart';

class GoalDbHelper {
  static final GoalDbHelper instance = GoalDbHelper._init();
  static Database? _database;

  GoalDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('goals.db');
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
    await db.execute('''
      CREATE TABLE goals(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL,
        deadline TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        completion_date TEXT,
        is_synced INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<void> insertGoal(Goal goal) async {
    final db = await database;
    await db.insert(
      'goals',
      {
        'id': goal.id,
        'name': goal.name,
        'target_amount': goal.targetAmount,
        'current_amount': goal.currentAmount,
        'deadline': goal.deadline.toIso8601String(),
        'completed': goal.completed ? 1 : 0,
        'completion_date': goal.completionDate?.toIso8601String(),
        'is_synced': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Goal>> getAllGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('goals');

    return List.generate(maps.length, (i) {
      return Goal.fromJson({
        '_id': maps[i]['id'],
        'name': maps[i]['name'],
        'target_amount': maps[i]['target_amount'],
        'current_amount': maps[i]['current_amount'],
        'deadline': maps[i]['deadline'],
        'completed': maps[i]['completed'] == 1,
        'completion_date': maps[i]['completion_date'],
      });
    });
  }

  Future<void> updateGoal(Goal goal) async {
    final db = await database;
    await db.update(
      'goals',
      {
        'name': goal.name,
        'target_amount': goal.targetAmount,
        'current_amount': goal.currentAmount,
        'deadline': goal.deadline.toIso8601String(),
        'completed': goal.completed ? 1 : 0,
        'completion_date': goal.completionDate?.toIso8601String(),
        'is_synced': 1,
      },
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> deleteGoal(String id) async {
    final db = await database;
    await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllGoals() async {
    final db = await database;
    await db.delete('goals');
  }
}