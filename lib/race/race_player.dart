import 'dart:ui';

class RacePlayer {
  final String userId;
  final String username;
  final int steps;

  final Color color;
  final bool isCurrent;
  final int thumbsUpCount;
  final bool hasSentThumbsUp;

  const RacePlayer({
    required this.userId,
    required this.username,
    required this.steps,
    required this.color,
    this.isCurrent = false,
    this.thumbsUpCount = 0,
    this.hasSentThumbsUp = false,
  });

  static Color getTierColor(int steps) {
    if (steps < 5000) {
      return const Color(0xFF1A1A1A); // 0 - 4,999 (Matte Black)
    } else if (steps < 8500) {
      return const Color(0xFF00FF00); // 5,000 - 8,499 (Vibrant Green)
    } else if (steps < 10000) {
      return const Color(0xFF448AFF); // 8,500 - 9,999 (Electric Blue - "Good Daily")
    } else if (steps < 15000) {
      return const Color(0xFFFFB300); // 10,000 - 14,999 (Radiant Gold - GOAL HIT)
    } else if (steps < 20000) {
      return const Color(0xFFFF007F); // 15,000 - 19,999 (Hot Magenta)
    } else {
      return const Color(0xFF00E5FF); // 20,000+ (Cyber Cyan - Easter Egg)
    }
  }

  factory RacePlayer.fromJson(Map<String, dynamic> json, {bool isCurrent = false}) {
    final steps = json['steps'] as int? ?? 0;
    final thumbsUpCount = (json['thumbsUpCount'] ?? json['ThumbsUpCount'] ?? 0) as int;
    final hasSentThumbsUp = (json['hasSentThumbsUp'] ?? json['HasSentThumbsUp'] ?? false) as bool;

    return RacePlayer(
      userId: json['userId'] as String,
      username: json['firstName'] as String,
      steps: steps,
      color: getTierColor(steps),
      isCurrent: isCurrent,
      thumbsUpCount: thumbsUpCount,
      hasSentThumbsUp: hasSentThumbsUp,
    );
  }
}
