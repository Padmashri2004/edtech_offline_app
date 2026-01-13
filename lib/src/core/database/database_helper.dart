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
    // Note: If you already ran the app, you might need to uninstall it 
    // to reset the DB version, or change version to 2 here.
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. Exams Table (Matches ExamModel)
    await db.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        difficulty TEXT NOT NULL, -- FIXED: Was 'tier'
        timestamp TEXT NOT NULL,  -- FIXED: Was 'created_at'
        is_digital INTEGER DEFAULT 1, 
        timer_minutes INTEGER DEFAULT 30
      )
    ''');

    // 2. Questions Table (Matches QuestionModel)
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER, -- FIXED: Was 'assessment_id'
        type TEXT DEFAULT 'mcq', 
        question_text TEXT NOT NULL,
        options TEXT NOT NULL, 
        correct_answer TEXT NOT NULL,
        explanation TEXT, -- FIXED: Was 'xai_explanation'
        marks INTEGER DEFAULT 1,
        FOREIGN KEY (exam_id) REFERENCES exams (id) ON DELETE CASCADE
      )
    ''');
    
    // REMOVED: users, alumni_connections (Member 2 tasks)
  }
}