import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'user_model.dart';

class AuthDB {
  AuthDB._();
  static final AuthDB instance = AuthDB._();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'auth.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            role TEXT,
            salutation TEXT,
            name TEXT,
            email TEXT UNIQUE,
            password TEXT,

            studentClass TEXT,
            studentSection TEXT,

            classesHandled TEXT,
            subjectsHandled TEXT,
            isClassTeacher INTEGER,
            classTeacherClass TEXT,
            classTeacherSection TEXT,

            children TEXT
          )
        ''');
      },
    );
  }

  // ---------- REGISTER ----------
  Future<void> register(UserModel user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------- LOGIN ----------
  Future<UserModel?> login(String email, String password) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (res.isEmpty) return null;
    return UserModel.fromMap(res.first);
  }

  // ---------- RESET PASSWORD ----------
  Future<bool> resetPassword(String email, String newPassword) async {
    final db = await database;
    final count = await db.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );
    return count > 0;
  }
}
