import 'package:edtech_offline_app/src/core/database/database_helper.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

class AlumniEngine {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // Initialize the logger
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0), // Clean logs without stack traces
  );

  /// Logic to promote students and handle Grade 8 graduation every June
  static Future<void> checkAndPromoteStudents() async {
    final now = DateTime.now();
    final settingsBox = Hive.box('settings');
    
    int lastPromotionYear = settingsBox.get('lastPromotionYear', defaultValue: 0);

    // Requirement: Transitions happen in June (Month 6)
    if (now.month == 6 && now.year > lastPromotionYear) {
      try {
        final db = await _dbHelper.database;

        await db.transaction((txn) async {
          // 1. Move Grade 8 students to 'alumni' role
          int graduates = await txn.rawUpdate('''
            UPDATE users 
            SET role = 'alumni' 
            WHERE role = 'student' AND class_id = 8
          ''');

          // 2. Promote Grades 1-7 to the next level
          int promoted = await txn.rawUpdate('''
            UPDATE users 
            SET class_id = class_id + 1 
            WHERE role = 'student' AND class_id < 8
          ''');

          _logger.i("Academic transition completed. Graduates: $graduates, Promoted: $promoted");
        });

        // Record successful run
        await settingsBox.put('lastPromotionYear', now.year);
        
      } catch (e) {
        _logger.e("Failed to process alumni transition: ${e.toString()}");
      }
    } else {
      _logger.d("AlumniEngine: No promotion required for today's date.");
    }
  }
}