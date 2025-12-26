/// Pinged section (content shared from female to male)
class PingedSection {
  final String id; // UUID
  final int chapterNumber;
  final String sectionId;
  final String sectionTitle;
  final String sectionContentJson; // Serialized ContentBlocks
  final DateTime pingedAt;
  final bool synced;
  final bool readByPartner;
  final DateTime? readAt;

  PingedSection({
    required this.id,
    required this.chapterNumber,
    required this.sectionId,
    required this.sectionTitle,
    required this.sectionContentJson,
    required this.pingedAt,
    this.synced = false,
    this.readByPartner = false,
    this.readAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapter_number': chapterNumber,
      'section_id': sectionId,
      'section_title': sectionTitle,
      'section_content_json': sectionContentJson,
      'pinged_at': pingedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
      'read_by_partner': readByPartner ? 1 : 0,
      'read_at': readAt?.toIso8601String(),
    };
  }

  factory PingedSection.fromMap(Map<String, dynamic> map) {
    return PingedSection(
      id: map['id'] as String,
      chapterNumber: map['chapter_number'] as int,
      sectionId: map['section_id'] as String,
      sectionTitle: map['section_title'] as String,
      sectionContentJson: map['section_content_json'] as String,
      pingedAt: DateTime.parse(map['pinged_at'] as String),
      synced: (map['synced'] as int) == 1,
      readByPartner: (map['read_by_partner'] as int) == 1,
      readAt: map['read_at'] != null
          ? DateTime.parse(map['read_at'] as String)
          : null,
    );
  }
}

/// Discussion message
class DiscussionMessage {
  final String id; // UUID
  final int chapterNumber;
  final String sender; // 'female' or 'male'
  final String messageText;
  final DateTime sentAt;
  final bool synced;
  final DateTime? autoDeleteAt;

  DiscussionMessage({
    required this.id,
    required this.chapterNumber,
    required this.sender,
    required this.messageText,
    required this.sentAt,
    this.synced = false,
    this.autoDeleteAt,
  });

  bool get isFemale => sender == 'female';
  bool get isMale => sender == 'male';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapter_number': chapterNumber,
      'sender': sender,
      'message_text': messageText,
      'sent_at': sentAt.toIso8601String(),
      'synced': synced ? 1 : 0,
      'auto_delete_at': autoDeleteAt?.toIso8601String(),
    };
  }

  factory DiscussionMessage.fromMap(Map<String, dynamic> map) {
    return DiscussionMessage(
      id: map['id'] as String,
      chapterNumber: map['chapter_number'] as int,
      sender: map['sender'] as String,
      messageText: map['message_text'] as String,
      sentAt: DateTime.parse(map['sent_at'] as String),
      synced: (map['synced'] as int) == 1,
      autoDeleteAt: map['auto_delete_at'] != null
          ? DateTime.parse(map['auto_delete_at'] as String)
          : null,
    );
  }
}

/// Question exchange
class QuestionExchange {
  final String id; // UUID
  final int chapterNumber;
  final String questionText;
  final DateTime askedAt;
  final bool synced;
  final String? answerText;
  final DateTime? answeredAt;
  final bool discussionOpened;

  QuestionExchange({
    required this.id,
    required this.chapterNumber,
    required this.questionText,
    required this.askedAt,
    this.synced = false,
    this.answerText,
    this.answeredAt,
    this.discussionOpened = false,
  });

  bool get isAnswered => answerText != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapter_number': chapterNumber,
      'question_text': questionText,
      'asked_at': askedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
      'answer_text': answerText,
      'answered_at': answeredAt?.toIso8601String(),
      'discussion_opened': discussionOpened ? 1 : 0,
    };
  }

  factory QuestionExchange.fromMap(Map<String, dynamic> map) {
    return QuestionExchange(
      id: map['id'] as String,
      chapterNumber: map['chapter_number'] as int,
      questionText: map['question_text'] as String,
      askedAt: DateTime.parse(map['asked_at'] as String),
      synced: (map['synced'] as int) == 1,
      answerText: map['answer_text'] as String?,
      answeredAt: map['answered_at'] != null
          ? DateTime.parse(map['answered_at'] as String)
          : null,
      discussionOpened: (map['discussion_opened'] as int?) == 1,
    );
  }
}
