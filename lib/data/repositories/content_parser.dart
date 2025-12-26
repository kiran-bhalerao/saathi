import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/chapter_model.dart';
import '../../config/constants.dart';

/// Content parser - converts Markdown files to structured Chapter models
class ContentParser {
  final Uuid _uuid = const Uuid();

  /// Load and parse a chapter from markdown file
  Future<Chapter> parseChapter(int chapterNumber, {String locale = 'en'}) async {
    final path = '${AppConstants.chaptersPathEn}chapters/chapter_${chapterNumber.toString().padLeft(2, '0')}_*.md';
    
    // Load markdown file
    final String markdown = await _loadChapterFile(chapterNumber, locale);
    
    // Parse into structured Chapter model
    return _parseMarkdown(markdown, chapterNumber);
  }

  /// Load chapter markdown file
  Future<String> _loadChapterFile(int chapterNumber, String locale) async {
    final filename = await _getChapterFilename(chapterNumber, locale);
    return await rootBundle.loadString(filename);
  }

  /// Get chapter filename by number
  Future<String> _getChapterFilename(int chapterNumber, String locale) async {
    final basePath = locale == 'en' 
        ? AppConstants.chaptersPathEn 
        : AppConstants.chaptersPathHi;
    
    // Map of chapter numbers to their filenames
    // This avoids needing to parse AssetManifest.json
    final chapterFilenames = {
      1: 'chapter_01_the_partnership.md',
      2: 'chapter_02_female_garden.md',
      3: 'chapter_03_baby_maker.md',
      4: 'chapter_04_magic_button.md',
      5: 'chapter_05_ladder_to_stars.md',
      6: 'chapter_06_orgasm_gap.md',
      7: 'chapter_07_making_it_work.md',
      8: 'chapter_08_oral_sex.md',
      9: 'chapter_09_back_door.md',
      10: 'chapter_10_spicing_it_up.md',
      11: 'chapter_11_feedback_loop.md',
      12: 'chapter_12_aftercare.md',
    };
    
    final filename = chapterFilenames[chapterNumber];
    if (filename == null) {
      throw Exception('Chapter $chapterNumber not found');
    }
    
    return '$basePath$filename';
  }

  /// Parse markdown content into Chapter model
  Chapter _parseMarkdown(String markdown, int chapterNumber) {
    final lines = markdown.split('\n');
    
    String title = '';
    String subtitle = '';
    final List<Section> sections = [];
    final List<VocabularyTerm> vocabulary = [];
    ReflectionBlock? reflection;
    String? comingUpNext;
    
    int wordCount = 0;
    List<ContentBlock> currentBlocks = [];
    String? currentSectionTitle;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Skip empty lines and horizontal rules
      if (line.isEmpty || line == '---') continue;
      
      // Chapter title (# Chapter X: Title)
      if (line.startsWith('# Chapter $chapterNumber:')) {
        title = line.replaceFirst('# Chapter $chapterNumber:', '').trim();
        continue;
      }
      
      // Subtitle (## Subtitle) - only the first ## before any sections
      if (line.startsWith('##') && !line.startsWith('###') && subtitle.isEmpty && sections.isEmpty) {
        subtitle = line.replaceFirst('##', '').trim();
        continue;
      }
      
      // Section heading (## or ###)
      if (line.startsWith('##') || line.startsWith('###')) {
        // Skip horizontal rules
        if (line.trim() == '---') {
          continue;
        }
        
        // Save previous section
        if (currentSectionTitle != null && currentBlocks.isNotEmpty) {
          sections.add(Section(
            id: _uuid.v4(),
            title: currentSectionTitle,
            blocks: List.from(currentBlocks),
          ));
          currentBlocks.clear();
        }
        
        currentSectionTitle = line.replaceAll(RegExp(r'^#{2,3}\s*'), '');
        
        // Check for special sections
        if (currentSectionTitle == 'New Words You\'ll Know') {
          // Parse vocabulary section
          vocabulary.addAll(_parseVocabulary(lines, i + 1, chapterNumber));
          currentSectionTitle = null; // Don't create a section for this
          continue;
        }
        
        if (currentSectionTitle == 'Something to Think About') {
          // Parse reflection question
          reflection = _parseReflection(lines, i + 1);
          currentSectionTitle = null;
          continue;
        }
        
        if (currentSectionTitle == 'Coming Up Next') {
          comingUpNext = _extractComingUpNext(lines, i + 1);
          currentSectionTitle = null;
          continue;
        }
        
        continue;
      }
      
      // Skip if no section started yet
      if (currentSectionTitle == null) continue;
      
      // Parse content blocks
      currentBlocks.add(_parseContentLine(line, lines, i));
      wordCount += line.split(' ').length;
    }
    
    // Add final section
    if (currentSectionTitle != null && currentBlocks.isNotEmpty) {
      sections.add(Section(
        id: _uuid.v4(),
        title: currentSectionTitle,
        blocks: List.from(currentBlocks),
      ));
    }
    
    return Chapter(
      number: chapterNumber,
      title: title,
      subtitle: subtitle,
      sections: sections,
      vocabulary: vocabulary,
      reflection: reflection,
      comingUpNext: comingUpNext,
      wordCount: wordCount,
      estimatedReadMinutes: (wordCount / AppConstants.averageWordsPerMinute).ceil(),
    );
  }

  /// Parse a content line into appropriate ContentBlock
  ContentBlock _parseContentLine(String line, List<String> allLines, int currentIndex) {
    // Code block (starts with backticks or indented)
    if (line.startsWith('```')) {
      return _parseCodeBlock(allLines, currentIndex);
    }
    
    // List item
    if (line.startsWith('- ') || line.startsWith('* ') || RegExp(r'^\d+\.').hasMatch(line)) {
      return _parseList(line, line.startsWith(RegExp(r'^\d+')));
    }
    
    // Heading
    if (line.startsWith('###')) {
      return HeadingBlock(
        text: line.replaceFirst('###', '').trim(),
        level: 3,
      );
    }
    
    if (line.startsWith('####')) {
      return HeadingBlock(
        text: line.replaceFirst('####', '').trim(),
        level: 4,
      );
    }
    
    // Story block (italic paragraph)
    if (line.startsWith('*') && line.endsWith('*') && !line.startsWith('* ')) {
      return StoryBlock(
        content: line.replaceAll('*', '').trim(),
      );
    }
    
    // Regular paragraph
    return ParagraphBlock(text: line);
  }

  /// Parse code block (ASCII diagrams)
  CodeBlock _parseCodeBlock(List<String> lines, int startIndex) {
    final buffer = StringBuffer();
    int i = startIndex + 1;
    
    while (i < lines.length && !lines[i].trim().startsWith('```')) {
      buffer.writeln(lines[i]);
      i++;
    }
    
    return CodeBlock(content: buffer.toString().trim());
  }

  /// Parse list block
  ListBlock _parseList(String line, bool ordered) {
    final items = <String>[];
    final item = line.replaceFirst(RegExp(r'^(\d+\.|-|\*)\s*'), '');
    items.add(item);
    
    return ListBlock(items: items, ordered: ordered);
  }

  /// Parse vocabulary section
  List<VocabularyTerm> _parseVocabulary(List<String> lines, int startIndex, int chapterNumber) {
    final terms = <VocabularyTerm>[];
    
    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Stop at next section
      if (line.startsWith('##')) break;
      if (line.isEmpty) continue;
      
      // Format: **Term**: Definition
      if (line.startsWith('**')) {
        final parts = line.split('**:');
        if (parts.length == 2) {
          final term = parts[0].replaceAll('**', '').trim();
          final definition = parts[1].trim();
          
          terms.add(VocabularyTerm(
            term: term,
            definition: definition,
            chapterNumber: chapterNumber,
          ));
        }
      }
    }
    
    return terms;
  }

  /// Parse reflection question
  ReflectionBlock? _parseReflection(List<String> lines, int startIndex) {
    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.startsWith('##')) break;
      if (line.isEmpty) continue;
      
      return ReflectionBlock(question: line);
    }
    
    return null;
  }

  /// Extract "Coming Up Next" text
  String? _extractComingUpNext(List<String> lines, int startIndex) {
    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.startsWith('##')) break;
      if (line.isEmpty) continue;
      
      return line;
    }
    
    return null;
  }
}
