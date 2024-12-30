import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';

class TransactionDbHelper {
  static final TransactionDbHelper instance = TransactionDbHelper._init();
  static Database? _database;

  TransactionDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transactions.db');
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
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<void> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.insert(
      'transactions',
      {
        'id': transaction.id,
        'type': transaction.type,
        'amount': transaction.amount,
        'category': transaction.category,
        'date': transaction.date.toIso8601String(),
        'is_synced': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    // Modified query to sort by date in descending order (newest first)
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return TransactionModel.fromJson(maps[i]);
    });
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      {
        'type': transaction.type,
        'amount': transaction.amount,
        'category': transaction.category,
        'date': transaction.date.toIso8601String(),
        'is_synced': 1,
      },
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllTransactions() async {
    final db = await database;
    await db.delete('transactions');
  }
}