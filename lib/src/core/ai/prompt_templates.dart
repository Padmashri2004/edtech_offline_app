class PromptTemplates {
  /// Template for the Quiz Generation logic (Member 1 specialty)
  static String quizGeneration({
    required String context, 
    required String difficulty,
  }) {
    return """
You are an expert teacher. Based on the text below, generate 5 MCQs.
Difficulty: $difficulty

Rules:
1. Provide 1 correct answer and 3 distractor options.
2. Format as a raw JSON array of objects.

Text: $context

JSON Format Example:
[{"question": "text", "options": ["A", "B", "C", "D"], "answer": 0}]
""";
  }

  /// Template for XAI (Explain My Mistake)
  static String xaiExplain(String question, String wrongChoice) {
    return "The student chose '$wrongChoice' for the question: '$question'. Explain in 1 simple sentence why this is a common mistake and what the correct concept is.";
  }
}