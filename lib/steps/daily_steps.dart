class DailySteps {
  final String firstName;
  final int steps;
  final String userId;

  DailySteps({required this.firstName, required this.steps, required this.userId});

  factory DailySteps.fromJson(Map<String, dynamic> json) {
    return DailySteps(
      firstName: (json['firstName'] ?? json['FirstName'] ?? json['username'] ?? '').toString(),
      steps: ((json['steps'] ?? json['Steps'] ?? 0) as num).toInt(),
      userId: (json['userId'] ?? json['UserId'] ?? json['id'] ?? '').toString(),
    );
  }
}
