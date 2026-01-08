import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('edtech_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path, 
      version: 1, 
      onCreate: _createDB
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Table for AI-generated Quizzes & Exams (Modules 1 & 6)
    await db.execute('''
      CREATE TABLE ContentLibrary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        body TEXT,
        type TEXT, -- 'quiz' or 'exam'
        complexity TEXT, -- 'basic' or 'advanced'
        created_at TEXT
      )
    ''');

    // 2. Table for your Image Library (Your new plan)
    await db.execute('''
      CREATE TABLE ImageLibrary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT,    -- Path to the saved .png in app docs
        original_page INTEGER,
        tags TEXT,          -- AI generated tags: 'cell', 'mitosis', etc.
        description TEXT,   -- Context extracted from surrounding text
        source_pdf TEXT
      )
    ''');

    // 3. Table for Student Progress (Member 2)
    await db.execute('''
      CREATE TABLE StudentProgress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        module_id INTEGER,
        score REAL,
        completed_at TEXT
      )
    ''');
  }

  // --- Helper Methods for Your Task ---

  Future<int> insertImage(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('ImageLibrary', row);
  }

  Future<List<Map<String, dynamic>>> searchImagesByTag(String tag) async {
    Database db = await instance.database;
    return await db.query(
      'ImageLibrary', 
      where: 'tags LIKE ?', 
      whereArgs: ['%$tag%']
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}