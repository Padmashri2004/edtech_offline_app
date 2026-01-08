import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('edtech_full.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // MOD 1: Login & Roles
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT, email TEXT UNIQUE, password TEXT, role TEXT, 
        class_details TEXT, is_class_teacher INTEGER
      )
    ''');

    // MOD 6: Question Papers (Header)
    await db.execute('''
      CREATE TABLE assessments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT, tier TEXT, max_marks INTEGER DEFAULT 100, 
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // The Complex Question Table for Multi-format Papers
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        assessment_id INTEGER,
        type TEXT, -- mcq, fillup, match, sequence, assertion_reason, summary
        question_text TEXT,
        options TEXT, -- JSON for MCQs/Matching pairs
        correct_answer TEXT,
        hint TEXT, -- For Basic tier bracketed hints
        marks INTEGER,
        FOREIGN KEY (assessment_id) REFERENCES assessments (id)
      )
    ''');

    // MOD 7: Alumni Connect
    await db.execute('''
      CREATE TABLE alumni_connections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER, alumni_id INTEGER, status TEXT
      )
    ''');
  }
}