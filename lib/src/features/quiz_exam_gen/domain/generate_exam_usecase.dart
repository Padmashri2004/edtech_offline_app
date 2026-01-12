import 'package:edtech_offline_app/src/features/ai_assistant/data/ai_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/quiz_repository.dart';
import 'package:edtech_offline_app/src/features/quiz_exam_gen/data/models/exam_model.dart';

class GenerateExamUseCase {
  final AIRepository aiRepo;
  final QuizRepository quizRepo;

  GenerateExamUseCase(this.aiRepo, this.quizRepo);

  /// The "Magic" function: Generates via AI and immediately saves to DB
  Future<ExamModel?> execute({required String topic, required String content, required String level}) async {
    // 1. Get raw questions from AI
    final questionsData = await aiRepo.getQuizFromChapter(rawContent: content, difficulty: level);
    
    if (questionsData.isEmpty) return null;

    // 2. Map to our Question Model
    final questions = questionsData.map((q) => QuestionModel.fromMap(q)).toList();

    // 3. Create Exam Object
    final newExam = ExamModel(
      title: topic,
      difficulty: level,
      timestamp: DateTime.now().toIso8601String(),
      questions: questions,
    );

    // 4. Save to DB
    await quizRepo.saveExam(newExam);
    
    return newExam;
  }
}