import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(
        'edtech_core_final_v2.db'); // Changed name to force new DB creation
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. Exams Table
    // ADDED: assigned_students column to store list of student IDs/Names
    await db.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        difficulty TEXT NOT NULL, 
        timestamp TEXT NOT NULL, 
        is_digital INTEGER DEFAULT 1,
        timer_minutes INTEGER DEFAULT 30,
        assigned_students TEXT 
      )
    ''');

    // 2. Questions Table
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER,
        type TEXT DEFAULT 'mcq',
        question_text TEXT NOT NULL,
        options TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        explanation TEXT, 
        marks INTEGER DEFAULT 1,
        FOREIGN KEY (exam_id) REFERENCES exams (id) ON DELETE CASCADE
      )
    ''');

    // MODULE 2 - Student Tracking
    // 3. Student Progress Table
    await db.execute('''
      CREATE TABLE student_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL,
        subject TEXT NOT NULL,
        chapter TEXT NOT NULL,
        progress_percent INTEGER DEFAULT 0,
        last_updated TEXT
      )
    ''');

    // 4. Study Goals Table
    await db.execute('''
      CREATE TABLE study_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL,
        goal_title TEXT NOT NULL,
        target_date TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        created_at TEXT
      )
    ''');

    //MODULE 7 - Alumni & Mentorship
    // 5. Alumni Profiles Table
    await db.execute('''
      CREATE TABLE alumni_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        alumni_id TEXT NOT NULL,
        name TEXT NOT NULL,
        expertise TEXT NOT NULL,
        is_available INTEGER DEFAULT 1
      )
    ''');

    // 6. Mentorship Requests Table
    await db.execute('''
      CREATE TABLE mentorship_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL,
        alumni_id TEXT NOT NULL,
        status TEXT DEFAULT 'requested',
        requested_at TEXT
      )
    ''');
  }
}
