class StudentGoal {
  final String subject;
  final String chapter;
  final String topic;
  final DateTime targetDate;
  bool completed;

  StudentGoal({
    required this.subject,
    required this.chapter,
    required this.topic,
    required this.targetDate,
    this.completed = false,
  });
}
