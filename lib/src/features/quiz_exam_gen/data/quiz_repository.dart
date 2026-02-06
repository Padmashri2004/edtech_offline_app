// FIXED: Removed unused sqflite import
import 'package:edtech_offline_app/src/core/database/database_helper.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';
import 'package:logger/logger.dart';

class QuizRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Logger _logger = Logger();

  /// Saves a new AI-generated exam to the local database
  Future<int> saveExam(ExamModel exam) async {
    try {
      final db = await _dbHelper.database;

      // Use a Transaction to ensure both Exam and Questions are saved
      return await db.transaction((txn) async {
        _logger.i(" 💾 Saving exam header '${exam.title}'...");
        int examId = await txn.insert('exams', exam.toMap());

        int qCount = 0;
        for (var question in exam.questions) {
          final questionToSave = QuestionModel(
            examId: examId,
            questionText: question.questionText,
            options: question.options,
            correctAnswer: question.correctAnswer,
            explanation: question.explanation,
            marks: question.marks,
            imagePath: question.imagePath,
          );
          await txn.insert('questions', questionToSave.toMap());
          qCount++;
        }

        _logger
            .i(" ✅ Successfully saved Exam #$examId with $qCount questions.");
        return examId;
      });
    } catch (e) {
      _logger.e(" ❌ Error saving exam: $e");
      return -1;
    }
  }

  /// Retrieves all exams stored offline
  Future<List<ExamModel>> getAllExams() async {
    try {
      final db = await _dbHelper.database;
      final exams = await db.query('exams');
      List<ExamModel> examList = [];

      for (var examMap in exams) {
        final exam = ExamModel.fromMap(examMap);

        final questions = await db.query(
          'questions',
          where: 'exam_id = ?',
          whereArgs: [exam.id],
        );

        examList.add(ExamModel(
          id: exam.id,
          title: exam.title,
          difficulty: exam.difficulty,
          timestamp: exam.timestamp,
          timerMinutes: exam.timerMinutes,
          assignedStudents: exam.assignedStudents,
          questions: questions.map((q) => QuestionModel.fromMap(q)).toList(),
        ));
      }
      return examList;
    } catch (e) {
      _logger.e(" ❌ Error fetching exams: $e");
      return [];
    }
  }

  /// Deletes an exam and its questions
  Future<int> deleteExam(int examId) async {
    try {
      final db = await _dbHelper.database;

      // Delete questions linked to exam first
      await db.delete(
        'questions',
        where: 'exam_id = ?',
        whereArgs: [examId],
      );

      // Delete exam itself
      int count = await db.delete(
        'exams',
        where: 'id = ?',
        whereArgs: [examId],
      );

      _logger.i(" 🗑️ Deleted exam #$examId ($count rows)");
      return count;
    } catch (e) {
      _logger.e(" ❌ Error deleting exam: $e");
      return -1;
    }
  }
}
