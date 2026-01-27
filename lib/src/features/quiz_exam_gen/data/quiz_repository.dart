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
        _logger.i(" 💾  Member 1: Saving exam header '${exam.title}'...");

        int examId = await txn.insert('exams', exam.toMap());

        int qCount = 0;
        for (var question in exam.questions) {
          final questionToSave = QuestionModel(
            examId: examId,
            questionText: question.questionText,
            options: question.options,
            correctAnswer: question.correctAnswer,
            explanation: question.explanation,
            marks: question.marks, // ✅ ADD THIS LINE
            imagePath: question.imagePath, // ✅ ADD THIS LINE
          );

          await txn.insert('questions', questionToSave.toMap());
          qCount++;
        }

        _logger.i(
            " ✅  Member 1: Successfully saved Exam #$examId with $qCount questions.");
        return examId;
      });
    } catch (e) {
      _logger.e(" ❌  Member 1: Error saving exam: $e");
      return -1;
    }
  }

  /// Retrieves all exams stored offline
  Future<List<ExamModel>> getAllExams() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps =
          await db.query('exams', orderBy: 'timestamp DESC');

      List<ExamModel> exams = [];

      for (var map in maps) {
        var exam = ExamModel.fromMap(map);

        final List<Map<String, dynamic>> qMaps = await db
            .query('questions', where: 'exam_id = ?', whereArgs: [exam.id]);

        List<QuestionModel> questions =
            List.generate(qMaps.length, (i) => QuestionModel.fromMap(qMaps[i]));

        exams.add(ExamModel(
          id: exam.id,
          title: exam.title,
          difficulty: exam.difficulty,
          timestamp: exam.timestamp,
          questions: questions,
        ));
      }

      return exams;
    } catch (e) {
      _logger.e(" ❌  Member 1: Error fetching exams: $e");
      return [];
    }
  }

  /// Deletes an exam
  Future<void> deleteExam(int id) async {
    final db = await _dbHelper.database;
    await db.delete('exams', where: 'id = ?', whereArgs: [id]);
    await db.delete('questions', where: 'exam_id = ?', whereArgs: [id]);
    _logger.i(" 🗑️  Member 1: Exam $id deleted.");
  }
}
