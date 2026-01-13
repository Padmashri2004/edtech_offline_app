import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('edtech_core_final.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // MOD 1: User Identity (Teacher, Student, Parent)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role TEXT NOT NULL, 
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        salutation TEXT, -- ms, mr, mrs
        class_id INTEGER, 
        section TEXT,
        subject_handles TEXT, -- Checkbox for multiple subjects
        is_class_teacher INTEGER DEFAULT 0,
        parent_student_tag TEXT, -- Link parent to student profile ID
        points INTEGER DEFAULT 0, -- Rewards
        graduation_year INTEGER -- For Alumni transition logic
      )
    ''');

    // MOD 1 & 6: Assessment Engine (Quiz & Question Papers)
    await db.execute('''
      CREATE TABLE assessments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        tier TEXT NOT NULL, -- Basic / Advanced
        is_digital INTEGER NOT NULL, -- 1=App Quiz, 0=Physical Paper
        max_marks INTEGER,
        deadline TEXT,
        timer_minutes INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Questions with Distractor & XAI Logic
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        assessment_id INTEGER,
        type TEXT, -- mcq, fillups, match, assertion_reason
        question_text TEXT,
        options TEXT, -- JSON distractors
        correct_answer TEXT,
        xai_explanation TEXT, -- "Explain My Mistake"
        marks INTEGER,
        image_path TEXT, -- Textbook Image Library
        FOREIGN KEY (assessment_id) REFERENCES assessments (id)
      )
    ''');

    // MOD 7: Alumni Connect Approval
    await db.execute('''
      CREATE TABLE alumni_connections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER,
        alumni_id INTEGER,
        status TEXT DEFAULT 'pending', -- approved/pending
        FOREIGN KEY (student_id) REFERENCES users (id),
        FOREIGN KEY (alumni_id) REFERENCES users (id)
      )
    ''');
  }
}