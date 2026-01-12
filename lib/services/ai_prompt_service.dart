class AiPromptService {
  
  /// Generates the prompt based on level and content
  String buildQuizPrompt({
    required String text, 
    required String level, // 'Basic' or 'Advanced'
    int count = 5
  }) {
    return """
You are an expert Class 6 teacher. Generate $count Multiple Choice Questions (MCQs) from the text provided below.

DIFFICULTY LEVEL: $level

CONSTRAINTS:
1. Each question must have 1 correct answer and 3 "distractors" (plausible but wrong options).
2. Distractor Logic: Create wrong options based on common student misunderstandings of this topic.
3. XAI Requirement: For every question, provide a 1-sentence explanation for the correct answer.

OUTPUT FORMAT (JSON):
[
  {
    "question": "text",
    "options": ["A", "B", "C", "D"],
    "answer_index": 0,
    "explanation": "text"
  }
]

TEXT CONTENT:
$text
""";
  }

  /// Specialized prompt for XAI (when a student fails)
  String buildExplanationPrompt(String question, String studentAnswer, String correctAnswer, String context) {
    return """
The student answered "$studentAnswer" to the question "$question". 
The correct answer is "$correctAnswer".
Based on this textbook text: "$context", explain in simple words why the student's answer is a common mistake and why the correct answer is right.
""";
  }
}