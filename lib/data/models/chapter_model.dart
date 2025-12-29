/// Content block types for chapter sections
abstract class ContentBlock {
  const ContentBlock(); // Add default constructor

  String get type;
  Map<String, dynamic> toJson();

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'paragraph':
        return ParagraphBlock.fromJson(json);
      case 'list':
        return ListBlock.fromJson(json);
      case 'code':
        return CodeBlock.fromJson(json);
      case 'heading':
        return HeadingBlock.fromJson(json);
      case 'story':
        return StoryBlock.fromJson(json);
      case 'image':
        return ImageBlock.fromJson(json);
      default:
        throw Exception('Unknown content block type: $type');
    }
  }
}

/// Paragraph block with formatted text
class ParagraphBlock extends ContentBlock {
  final String text;
  final Map<String, bool>? formatting; // {bold: true, italic: false}

  ParagraphBlock({
    required this.text,
    this.formatting,
  });

  @override
  String get type => 'paragraph';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'text': text,
      'formatting': formatting,
    };
  }

  factory ParagraphBlock.fromJson(Map<String, dynamic> json) {
    return ParagraphBlock(
      text: json['text'] as String,
      formatting: json['formatting'] != null
          ? Map<String, bool>.from(json['formatting'] as Map)
          : null,
    );
  }
}

/// List block (bulleted or numbered)
class ListBlock extends ContentBlock {
  final List<String> items;
  final bool ordered;

  ListBlock({
    required this.items,
    this.ordered = false,
  });

  @override
  String get type => 'list';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'items': items,
      'ordered': ordered,
    };
  }

  factory ListBlock.fromJson(Map<String, dynamic> json) {
    return ListBlock(
      items: List<String>.from(json['items'] as List),
      ordered: json['ordered'] as bool? ?? false,
    );
  }
}

/// Code block (for ASCII diagrams)
class CodeBlock extends ContentBlock {
  final String content;

  CodeBlock({required this.content});

  @override
  String get type => 'code';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'content': content,
    };
  }

  factory CodeBlock.fromJson(Map<String, dynamic> json) {
    return CodeBlock(
      content: json['content'] as String,
    );
  }
}

/// Heading block
class HeadingBlock extends ContentBlock {
  final String text;
  final int level; // 3 or 4

  HeadingBlock({
    required this.text,
    required this.level,
  });

  @override
  String get type => 'heading';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'text': text,
      'level': level,
    };
  }

  factory HeadingBlock.fromJson(Map<String, dynamic> json) {
    return HeadingBlock(
      text: json['text'] as String,
      level: json['level'] as int,
    );
  }
}

/// Story block (narrative sections)
class StoryBlock extends ContentBlock {
  final String content;

  StoryBlock({required this.content});

  @override
  String get type => 'story';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'content': content,
    };
  }

  factory StoryBlock.fromJson(Map<String, dynamic> json) {
    return StoryBlock(
      content: json['content'] as String,
    );
  }
}

/// Image block
class ImageBlock extends ContentBlock {
  final String imagePath;
  final String? altText;

  ImageBlock({
    required this.imagePath,
    this.altText,
  });

  @override
  String get type => 'image';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'imagePath': imagePath,
      'altText': altText,
    };
  }

  factory ImageBlock.fromJson(Map<String, dynamic> json) {
    return ImageBlock(
      imagePath: json['imagePath'] as String,
      altText: json['altText'] as String?,
    );
  }
}

/// Section within a chapter
class Section {
  final String id; // UUID for ping tracking
  final String title;
  final List<ContentBlock> blocks;
  final List<String> keywords;

  Section({
    required this.id,
    required this.title,
    required this.blocks,
    this.keywords = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'blocks': blocks.map((b) => b.toJson()).toList(),
      'keywords': keywords,
    };
  }

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'] as String,
      title: json['title'] as String,
      blocks: (json['blocks'] as List)
          .map((b) => ContentBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
      keywords: List<String>.from(json['keywords'] as List? ?? []),
    );
  }
}

///  Quiz question model
class QuizQuestion {
  final String question;
  final bool correctAnswer; // true = Yes, false = No

  QuizQuestion({
    required this.question,
    required this.correctAnswer,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'correct_answer': correctAnswer,
    };
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] as String,
      correctAnswer: json['correct_answer'] as bool,
    );
  }
}

/// Vocabulary term
class VocabularyTerm {
  final String term;
  final String definition;
  final int chapterNumber;

  VocabularyTerm({
    required this.term,
    required this.definition,
    required this.chapterNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'term': term,
      'definition': definition,
      'chapter_number': chapterNumber,
    };
  }

  factory VocabularyTerm.fromJson(Map<String, dynamic> json) {
    return VocabularyTerm(
      term: json['term'] as String,
      definition: json['definition'] as String,
      chapterNumber: json['chapter_number'] as int,
    );
  }
}

/// Reflection block
class ReflectionBlock {
  final String question;

  ReflectionBlock({required this.question});

  Map<String, dynamic> toJson() {
    return {'question': question};
  }

  factory ReflectionBlock.fromJson(Map<String, dynamic> json) {
    return ReflectionBlock(
      question: json['question'] as String,
    );
  }
}

/// Chapter model
class Chapter {
  final int number;
  final String title;
  final String subtitle;
  final List<Section> sections;
  final List<VocabularyTerm> vocabulary;
  final List<QuizQuestion> quizQuestions;
  final ReflectionBlock? reflection;
  final String? comingUpNext;
  final int wordCount;
  final int estimatedReadMinutes;

  Chapter({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.sections,
    this.vocabulary = const [],
    this.quizQuestions = const [],
    this.reflection,
    this.comingUpNext,
    required this.wordCount,
    required this.estimatedReadMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'title': title,
      'subtitle': subtitle,
      'sections': sections.map((s) => s.toJson()).toList(),
      'vocabulary': vocabulary.map((v) => v.toJson()).toList(),
      'quiz_questions': quizQuestions.map((q) => q.toJson()).toList(),
      'reflection': reflection?.toJson(),
      'coming_up_next': comingUpNext,
      'word_count': wordCount,
      'estimated_read_minutes': estimatedReadMinutes,
    };
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      number: json['number'] as int,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      sections: (json['sections'] as List)
          .map((s) => Section.fromJson(s as Map<String, dynamic>))
          .toList(),
      vocabulary: (json['vocabulary'] as List? ?? [])
          .map((v) => VocabularyTerm.fromJson(v as Map<String, dynamic>))
          .toList(),
      quizQuestions: (json['quiz_questions'] as List? ?? [])
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      reflection: json['reflection'] != null
          ? ReflectionBlock.fromJson(json['reflection'] as Map<String, dynamic>)
          : null,
      comingUpNext: json['coming_up_next'] as String?,
      wordCount: json['word_count'] as int,
      estimatedReadMinutes: json['estimated_read_minutes'] as int,
    );
  }
}
