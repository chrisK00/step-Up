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
    final rawDate = json['date'] ?? json['Date'];
    DateTime parsedDate;
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return StepHistoryEntry(
      firstName: (json['firstName'] ?? json['FirstName'] ?? '').toString(),
      steps: ((json['steps'] ?? json['Steps'] ?? 0) as num).toInt(),
      userId: (json['userId'] ?? json['UserId'] ?? '').toString(),
      date: parsedDate,
    );
  }
}
