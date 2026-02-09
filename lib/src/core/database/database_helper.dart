import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('edtech_offline_v7.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    debugPrint(" 📂 DB Path: $path");

    return await openDatabase(
      path,
      version: 8, // bump version since schema changed
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Exams table (used for both quizzes and exams)
    await db.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        timer_minutes INTEGER NOT NULL,     -- ✅ teacher must provide timer
        total_marks INTEGER NOT NULL,       -- ✅ teacher must provide marks
        type TEXT NOT NULL                  -- "quiz" or "exam"
      )
    ''');

    // Questions table
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL,
        type TEXT NOT NULL,                 -- MCQ, True/False, etc.
        question_text TEXT NOT NULL,
        options TEXT,
        correct_answer TEXT NOT NULL,
        explanation TEXT,
        marks INTEGER NOT NULL,
        image_path TEXT,
        FOREIGN KEY (exam_id) REFERENCES exams (id) ON DELETE CASCADE
      )
    ''');

    // Question history (to avoid regenerating duplicates)
    await db.execute('''
      CREATE TABLE question_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_title TEXT,
        topic TEXT,
        question_hash TEXT UNIQUE,
        generated_at TEXT
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 8) {
      // Ensure required columns exist
      await db.execute(
          'ALTER TABLE exams ADD COLUMN type TEXT NOT NULL DEFAULT "quiz"');
      await db.execute(
          'ALTER TABLE exams ADD COLUMN timer_minutes INTEGER NOT NULL DEFAULT 30');
      await db.execute(
          'ALTER TABLE exams ADD COLUMN total_marks INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE questions ADD COLUMN type TEXT NOT NULL DEFAULT "MCQ"');
    }
  }
}
