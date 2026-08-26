class StepHistoryEntry {
  final String firstName;
  final int steps;
  final String userId;
  final DateTime date;

  StepHistoryEntry({
    required this.firstName,
    required this.steps,
    required this.userId,
    required this.date,
  });

  factory StepHistoryEntry.fromJson(Map<String, dynamic> json) {
    return StepHistoryEntry(
      firstName: json['firstName'],
      steps: json['steps'],
      userId: json['userId'],
      date: DateTime.parse(json['date']),
    );
  }
}
