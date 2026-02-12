import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('edtech_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    debugPrint("📂 DB Path: $path");

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // =========================
    // Exams table
    // =========================
    await db.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        type TEXT NOT NULL,                -- "quiz" or "exam"
        difficulty TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        timer_minutes INTEGER NOT NULL,
        total_marks INTEGER NOT NULL,
        published INTEGER NOT NULL DEFAULT 0,  -- ✅ ADDED: 0 = draft, 1 = published
        class_name TEXT,
        subject TEXT,
        textbook_name TEXT
      )
    ''');

    // =========================
    // Questions table
    // =========================
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL,          -- ✅ PRESENT: Foreign key to exams
        type TEXT NOT NULL,                 -- MCQ, True/False, Fill-up, etc.
        question_text TEXT NOT NULL,
        options TEXT,                       -- ✅ Stored as "|||" delimited string
        correct_answer TEXT NOT NULL,
        explanation TEXT,
        marks INTEGER NOT NULL,
        image_path TEXT,                    -- ✅ For picture-based questions
        FOREIGN KEY (exam_id) REFERENCES exams (id) ON DELETE CASCADE
      )
    ''');

    // =========================
    // Question history table (for deduplication)
    // =========================
    await db.execute('''
      CREATE TABLE question_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_title TEXT,
        topic TEXT,
        question_hash TEXT UNIQUE NOT NULL,  -- ✅ SHA-256 hash for dedup
        created_at TEXT NOT NULL             -- ✅ FIXED: Was "generated_at" before
      )
    ''');

    debugPrint("✅ Database tables created successfully");
  }

  // Helper method to clear all data (useful for testing)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('exams');
    await db.delete('questions');
    await db.delete('question_history');
    debugPrint("🗑️ All data cleared");
  }

  // Helper method to close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    debugPrint("🔒 Database closed");
  }
}
