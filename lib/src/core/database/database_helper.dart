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
    // --- MOD 1: User Identity (Teacher, Student, Parent) ---
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
        subject_handles TEXT, -- JSON or Comma-separated list
        is_class_teacher INTEGER DEFAULT 0,
        parent_student_tag TEXT, 
        points INTEGER DEFAULT 0,
        graduation_year INTEGER 
      )
    ''');

    // --- MOD 1 & 6: Assessment Engine (Quiz & Question Papers) ---
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

    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        assessment_id INTEGER,
        type TEXT, -- mcq, fillups, match, assertion_reason
        question_text TEXT,
        options TEXT, -- JSON distractors
        correct_answer TEXT,
        xai_explanation TEXT, -- "Explain My Mistake" logic
        marks INTEGER,
        image_path TEXT, 
        FOREIGN KEY (assessment_id) REFERENCES assessments (id) ON DELETE CASCADE
      )
    ''');

    // --- MOD 7: Alumni Connect Approval ---
    await db.execute('''
      CREATE TABLE alumni_connections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER,
        alumni_id INTEGER,
        status TEXT DEFAULT 'pending', 
        FOREIGN KEY (student_id) REFERENCES users (id),
        FOREIGN KEY (alumni_id) REFERENCES users (id)
      )
    ''');

    // --- PHASE 2: Unified Textbook Content ---
    await db.execute('''
      CREATE TABLE textbook_content (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        grade INTEGER,           -- 1 to 10
        subject_name TEXT,       -- 'Science', 'Mathematics', etc.
        sub_subject TEXT,        -- 'History', 'Geography' (For Class 9-10)
        book_part INTEGER,       -- 1 or 2
        chapter_index INTEGER,   -- Chapter number
        chapter_title TEXT,
        content_text TEXT,       -- Detailed text for Gemma AI
        is_downloaded INTEGER DEFAULT 0
      )
    ''');

    // --- NEW: Chapter Topics for Teacher Selection ---
    // This allows teachers to select specific sections for quizzes
    await db.execute('''
      CREATE TABLE chapter_topics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_id INTEGER,      -- Links to textbook_content.id
        topic_name TEXT,         -- e.g., "1.1 Food Variety"
        start_page INTEGER,
        FOREIGN KEY (content_id) REFERENCES textbook_content (id) ON DELETE CASCADE
      )
    ''');

    // --- PHASE 2: Textbook Media ---
    await db.execute('''
      CREATE TABLE textbook_media (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_id INTEGER,      -- Links to textbook_content.id
        image_label TEXT,        -- e.g., "Figure 1.1"
        image_path TEXT,         -- assets path or local storage path
        caption TEXT,
        FOREIGN KEY (content_id) REFERENCES textbook_content (id) ON DELETE CASCADE
      )
    ''');
  }
}