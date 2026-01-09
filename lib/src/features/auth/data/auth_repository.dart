import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/database/database_helper.dart';

class AuthRepository {
  final dbHelper = DatabaseHelper.instance;
  final _settingsBox = Hive.box('settings');

  // --- REGISTRATION LOGIC (Task 1) ---
  /// Registers a new user into the SQLite database.
  Future<int> registerUser(Map<String, dynamic> userData) async {
    final db = await dbHelper.database;
    return await db.insert('users', userData);
  }

  // --- LOGIN LOGIC (Task 2) ---
  /// Verifies credentials and manages session persistence.
  Future<Map<String, dynamic>?> loginUser(String email, String password, bool rememberMe) async {
    final db = await dbHelper.database;
    
    // Query database for matching email and password
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      final user = result.first;

      // If "Remember in app" is checked, persist the session in Hive
      if (rememberMe) {
        await _settingsBox.put('isLoggedIn', true);
        await _settingsBox.put('userId', user['id']);
        await _settingsBox.put('userRole', user['role']);
        await _settingsBox.put('userName', user['name']);
        // For Students: Store class and section for Module routing
        if (user['role'] == 'student') {
          await _settingsBox.put('userClass', user['class_id']);
        }
      }
      return user;
    }
    return null; // Login failed
  }

  // --- PASSWORD RESET LOGIC (Task 2.2) ---
  /// Simulates finding a user by email to trigger the reset flow.
  Future<bool> verifyEmailExists(String email) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  /// Updates the password for a verified email.
  Future<int> updatePassword(String email, String newPassword) async {
    final db = await dbHelper.database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  // --- SESSION MANAGEMENT ---
  /// Clears the persistent session (Logout).
  Future<void> logout() async {
    await _settingsBox.put('isLoggedIn', false);
    await _settingsBox.delete('userId');
    await _settingsBox.delete('userRole');
    await _settingsBox.delete('userName');
  }

  /// Checks current session status.
  bool isUserLoggedIn() {
    return _settingsBox.get('isLoggedIn', defaultValue: false);
  }

  String? getUserRole() {
    return _settingsBox.get('userRole');
  }
}