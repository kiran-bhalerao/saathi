/// Chapter progress tracking
class ChapterProgress {
  final int? id;
  final int chapterNumber;
  final bool completed;
  final String? currentSectionId;
  final DateTime? lastReadAt;
  final int readingTimeSeconds;
  final bool quizCompleted;
  final int? quizScore; // 0-5

  ChapterProgress({
    this.id,
    required this.chapterNumber,
    this.completed = false,
    this.currentSectionId,
    this.lastReadAt,
    this.readingTimeSeconds = 0,
    this.quizCompleted = false,
    this.quizScore,
  });

  /// Calculate progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (completed) return 1.0;
    // Will be calculated based on section progress
    return 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapter_number': chapterNumber,
      'completed': completed ? 1 : 0,
      'current_section_id': currentSectionId,
      'last_read_at': lastReadAt?.toIso8601String(),
      'reading_time_seconds': readingTimeSeconds,
      'quiz_completed': quizCompleted ? 1 : 0,
      'quiz_score': quizScore,
    };
  }

  factory ChapterProgress.fromMap(Map<String, dynamic> map) {
    return ChapterProgress(
      id: map['id'] as int?,
      chapterNumber: map['chapter_number'] as int,
      completed: (map['completed'] as int) == 1,
      currentSectionId: map['current_section_id'] as String?,
      lastReadAt: map['last_read_at'] != null
          ? DateTime.parse(map['last_read_at'] as String)
          : null,
      readingTimeSeconds: map['reading_time_seconds'] as int? ?? 0,
      quizCompleted: (map['quiz_completed'] as int?) == 1,
      quizScore: map['quiz_score'] as int?,
    );
  }

  ChapterProgress copyWith({
    int? id,
    int? chapterNumber,
    bool? completed,
    String? currentSectionId,
    DateTime? lastReadAt,
    int? readingTimeSeconds,
    bool? quizCompleted,
    int? quizScore,
  }) {
    return ChapterProgress(
      id: id ?? this.id,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      completed: completed ?? this.completed,
      currentSectionId: currentSectionId ?? this.currentSectionId,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      readingTimeSeconds: readingTimeSeconds ?? this.readingTimeSeconds,
      quizCompleted: quizCompleted ?? this.quizCompleted,
      quizScore: quizScore ?? this.quizScore,
    );
  }
}
