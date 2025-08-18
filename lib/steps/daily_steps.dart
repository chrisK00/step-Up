class DailySteps {
  final String firstName;
  final int steps;
  final String userId;

  DailySteps({required this.firstName, required this.steps, required this.userId});

  factory DailySteps.fromJson(Map<String, dynamic> json) {
    return DailySteps(
      firstName: json['firstName'],
      steps: json['steps'],
      userId: "//TODO",
    );
  }
}
