import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/reminder.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  // In-memory storage for web
  static final List<Reminder> _webReminders = [];

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'reminders.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reminders(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            dateTime TEXT NOT NULL,
            isCompleted INTEGER DEFAULT 0,
            isEnabled INTEGER DEFAULT 1,
            repeatType TEXT DEFAULT 'none',
            colorIndex INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<List<Reminder>> getAllReminders() async {
    if (kIsWeb) return List.from(_webReminders);
    
    final db = await database;
    final maps = await db.query('reminders', orderBy: 'dateTime ASC');
    return maps.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<void> insertReminder(Reminder reminder) async {
    if (kIsWeb) {
      _webReminders.add(reminder);
      return;
    }
    
    final db = await database;
    await db.insert('reminders', reminder.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateReminder(Reminder reminder) async {
    if (kIsWeb) {
      final index = _webReminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) _webReminders[index] = reminder;
      return;
    }
    
    final db = await database;
    await db.update('reminders', reminder.toMap(),
        where: 'id = ?', whereArgs: [reminder.id]);
  }

  Future<void> deleteReminder(String id) async {
    if (kIsWeb) {
      _webReminders.removeWhere((r) => r.id == id);
      return;
    }
    
    final db = await database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }
}
