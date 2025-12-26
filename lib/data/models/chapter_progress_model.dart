/// Chapter progress tracking
class ChapterProgress {
  final int? id;
  final int chapterNumber;
  final bool completed;
  final String? currentSectionId;
  final DateTime? lastReadAt;
  final int readingTimeSeconds;

  ChapterProgress({
    this.id,
    required this.chapterNumber,
    this.completed = false,
    this.currentSectionId,
    this.lastReadAt,
    this.readingTimeSeconds = 0,
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
    );
  }

  ChapterProgress copyWith({
    int? id,
    int? chapterNumber,
    bool? completed,
    String? currentSectionId,
    DateTime? lastReadAt,
    int? readingTimeSeconds,
  }) {
    return ChapterProgress(
      id: id ?? this.id,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      completed: completed ?? this.completed,
      currentSectionId: currentSectionId ?? this.currentSectionId,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      readingTimeSeconds: readingTimeSeconds ?? this.readingTimeSeconds,
    );
  }
}
