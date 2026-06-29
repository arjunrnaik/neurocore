import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/intent.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'neurocore.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        domain TEXT NOT NULL,
        action TEXT NOT NULL,
        raw_content TEXT NOT NULL,
        extracted_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_id INTEGER,
        message TEXT NOT NULL,
        due_at TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY(entry_id) REFERENCES entries(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE streaks (
        domain TEXT PRIMARY KEY,
        current_streak INTEGER DEFAULT 0,
        last_logged_date TEXT
      )
    ''');

    // Seed default streak counters
    for (final domain in ['health', 'finance', 'task']) {
      await db.insert('streaks', {'domain': domain, 'current_streak': 0, 'last_logged_date': ''});
    }
  }

  // Entries CRUD
  Future<int> insertEntry(EntryItem entry) async {
    final db = await database;
    final id = await db.insert('entries', entry.toMap());
    await _updateStreak(entry.domain);
    return id;
  }

  Future<List<EntryItem>> getEntries({String? domain}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;
    if (domain != null && domain.isNotEmpty && domain != 'all') {
      maps = await db.query('entries', where: 'domain = ?', whereArgs: [domain], orderBy: 'id DESC');
    } else {
      maps = await db.query('entries', orderBy: 'id DESC');
    }
    return maps.map((map) => EntryItem.fromMap(map)).toList();
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  // Reminders CRUD
  Future<int> insertReminder(ReminderItem reminder) async {
    final db = await database;
    return await db.insert('reminders', reminder.toMap());
  }

  Future<List<ReminderItem>> getReminders({String status = 'pending'}) async {
    final db = await database;
    final maps = await db.query('reminders', where: 'status = ?', whereArgs: [status], orderBy: 'due_at ASC');
    return maps.map((map) => ReminderItem.fromMap(map)).toList();
  }

  Future<int> toggleReminderStatus(int id, String newStatus) async {
    final db = await database;
    return await db.update('reminders', {'status': newStatus}, where: 'id = ?', whereArgs: [id]);
  }

  // Statistics & Streaks
  Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    final totalEntries = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM entries')) ?? 0;
    final pendingReminders = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM reminders WHERE status = 'pending'")) ?? 0;
    
    final streakRows = await db.query('streaks');
    final Map<String, int> streaks = {};
    for (final row in streakRows) {
      streaks[row['domain'] as String] = (row['current_streak'] as int?) ?? 0;
    }

    return {
      'total_entries': totalEntries,
      'pending_reminders': pendingReminders,
      'streaks': streaks,
    };
  }

  Future<void> _updateStreak(String domain) async {
    if (!['health', 'finance', 'task'].contains(domain)) return;
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final rows = await db.query('streaks', where: 'domain = ?', whereArgs: [domain]);
    if (rows.isNotEmpty) {
      final lastDate = rows.first['last_logged_date'] as String?;
      int streak = (rows.first['current_streak'] as int?) ?? 0;
      if (lastDate != today) {
        streak += 1;
        await db.update('streaks', {'current_streak': streak, 'last_logged_date': today}, where: 'domain = ?', whereArgs: [domain]);
      }
    }
  }
}
