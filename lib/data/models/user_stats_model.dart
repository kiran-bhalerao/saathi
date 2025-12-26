/// User statistics for gamification
class UserStats {
  final int? id;
  final int chaptersCompleted;
  final int knowledgePoints;
  final int readingStreakDays;
  final DateTime? lastReadDate;
  final int sectionsShared;
  final int questionsAnswered;
  final int totalReadingMinutes;

  UserStats({
    this.id,
    this.chaptersCompleted = 0,
    this.knowledgePoints = 0,
    this.readingStreakDays = 0,
    this.lastReadDate,
    this.sectionsShared = 0,
    this.questionsAnswered = 0,
    this.totalReadingMinutes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapters_completed': chaptersCompleted,
      'knowledge_points': knowledgePoints,
      'reading_streak_days': readingStreakDays,
      'last_read_date': lastReadDate?.toIso8601String(),
      'sections_shared': sectionsShared,
      'questions_answered': questionsAnswered,
      'total_reading_minutes': totalReadingMinutes,
    };
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      id: map['id'] as int?,
      chaptersCompleted: map['chapters_completed'] as int? ?? 0,
      knowledgePoints: map['knowledge_points'] as int? ?? 0,
      readingStreakDays: map['reading_streak_days'] as int? ?? 0,
      lastReadDate: map['last_read_date'] != null
          ? DateTime.parse(map['last_read_date'] as String)
          : null,
      sectionsShared: map['sections_shared'] as int? ?? 0,
      questionsAnswered: map['questions_answered'] as int? ?? 0,
      totalReadingMinutes: map['total_reading_minutes'] as int? ?? 0,
    );
  }

  UserStats copyWith({
    int? id,
    int? chaptersCompleted,
    int? knowledgePoints,
    int? readingStreakDays,
    DateTime? lastReadDate,
    int? sectionsShared,
    int? questionsAnswered,
    int? totalReadingMinutes,
  }) {
    return UserStats(
      id: id ?? this.id,
      chaptersCompleted: chaptersCompleted ?? this.chaptersCompleted,
      knowledgePoints: knowledgePoints ?? this.knowledgePoints,
      readingStreakDays: readingStreakDays ?? this.readingStreakDays,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      sectionsShared: sectionsShared ?? this.sectionsShared,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      totalReadingMinutes: totalReadingMinutes ?? this.totalReadingMinutes,
    );
  }
}

/// Achievement
class Achievement {
  final String id; // UUID
  final String title;
  final String description;
  final String? icon;
  final String? unlockCriteriaJson;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.icon,
    this.unlockCriteriaJson,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'unlock_criteria_json': unlockCriteriaJson,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      icon: map['icon'] as String?,
      unlockCriteriaJson: map['unlock_criteria_json'] as String?,
      unlockedAt: map['unlocked_at'] != null
          ? DateTime.parse(map['unlocked_at'] as String)
          : null,
    );
  }
}
