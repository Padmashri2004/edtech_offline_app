import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(
        'edtech_offline_v4.db'); // Incremented version for Auth update
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    debugPrint(" 📂  DB Path: $path");

    return await openDatabase(
      path,
      version: 4, // Increment version
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // --- 1. USER & AUTH TABLES (New for Mod 2/Login) ---
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT CHECK(role IN ('teacher', 'student', 'parent')) NOT NULL,
        full_name TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE students (
        user_id INTEGER PRIMARY KEY,
        class_grade TEXT NOT NULL,
        section TEXT NOT NULL,
        roll_number INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE teachers (
        user_id INTEGER PRIMARY KEY,
        subjects TEXT, -- JSON array: ["Math", "Science"]
        is_class_teacher INTEGER DEFAULT 0,
        class_teacher_for TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // --- 2. EXISTING EXAM TABLES (Preserved) ---
    const examTable = '''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        timer_minutes INTEGER DEFAULT 30
      )
    ''';

    const questionTable = '''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL,
        question_text TEXT NOT NULL,
        options TEXT,
        correct_answer TEXT NOT NULL,
        explanation TEXT,
        marks INTEGER DEFAULT 1,
        image_path TEXT,
        FOREIGN KEY (exam_id) REFERENCES exams (id) ON DELETE CASCADE
      )
    ''';

    // NEW: Question History for Deduplication (Mod 1/6)
    const historyTable = '''
      CREATE TABLE question_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_title TEXT,
        topic TEXT,
        question_hash TEXT,
        generated_at TEXT
      )
    ''';

    await db.execute(examTable);
    await db.execute(questionTable);
    await db.execute(historyTable);

    debugPrint(" ✅  Database v4 Created with Auth & Schema updates");
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint(" ⚠️  Upgrading DB from $oldVersion to $newVersion");

    if (oldVersion < 4) {
      // Create missing tables if upgrading
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            role TEXT CHECK(role IN ('teacher', 'student', 'parent')) NOT NULL,
            full_name TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS students (
            user_id INTEGER PRIMARY KEY,
            class_grade TEXT NOT NULL,
            section TEXT NOT NULL,
            roll_number INTEGER,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS teachers (
            user_id INTEGER PRIMARY KEY,
            subjects TEXT,
            is_class_teacher INTEGER DEFAULT 0,
            class_teacher_for TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
        debugPrint(" ✅  Migrated to v4 (Auth Tables Added)");
      } catch (e) {
        debugPrint("Error migrating auth tables: $e");
      }
    }
  }
}
