import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/app_colors.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/models/chapter_progress_model.dart';
import '../../../data/repositories/chapter_progress_repository.dart';
import 'chapter_discussion_screen.dart';
import 'chapter_quiz_screen.dart';

/// Chapter reader screen - displays chapter content with rich formatting
class ChapterReaderScreen extends StatefulWidget {
  final Chapter chapter;

  const ChapterReaderScreen({
    super.key,
    required this.chapter,
  });

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  final ChapterProgressRepository _progressRepo = ChapterProgressRepository();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _markAsStarted();
  }

  Future<void> _markAsStarted() async {
    await _progressRepo.updateProgress(ChapterProgress(
      chapterNumber: widget.chapter.number,
      lastReadAt: DateTime.now(),
      completed: false,
    ));
  }

  Future<void> _markAsCompleted() async {
    await _progressRepo.markChapterCompleted(widget.chapter.number);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE57373), width: 1.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Color(0xFFE57373), size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chapter ${widget.chapter.number}',
          style: const TextStyle(
            color: Color(0xFF2D2D2D),
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFE57373), size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChapterDiscussionScreen(chapter: widget.chapter),
                ),
              );
            },
            tooltip: 'Discussion',
          ),
        ],

      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Divider under app bar
            Container(
              height: 1,
              color: Colors.grey[200],
            ),
            
            // Chapter title header
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
              child: Text(
                widget.chapter.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                  height: 1.3,
                ),
              ),
            ),
            
            // Content sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Render each section
                  for (int i = 0; i < widget.chapter.sections.length; i++) ...[
                    _buildSection(widget.chapter.sections[i], i),
                    if (i < widget.chapter.sections.length - 1)
                      const SizedBox(height: 32),
                  ],
                  
                  const SizedBox(height: 40),
                  
                  // Take quiz button
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE57373),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.chapter.quizQuestions.isEmpty) {
                            // No quiz - just mark as complete
                            _markAsCompleted().then((_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Chapter completed! 🎉'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            });
                          } else {
                            // Navigate to quiz
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChapterQuizScreen(chapter: widget.chapter),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.chapter.quizQuestions.isEmpty 
                                  ? Icons.check_circle_outline 
                                  : Icons.quiz_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.chapter.quizQuestions.isEmpty
                                  ? 'Mark as Completed'
                                  : 'Take Quiz',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(Section section, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Expanded(
              child: Text(
                section.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                  height: 1.3,
                ),
              ),
            ),
            // Share button
            IconButton(
              icon: Icon(
                Icons.share_outlined,
                size: 20,
                color: Colors.grey[400],
              ),
              onPressed: () => _shareSection(section),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Section content
        ...section.blocks.map((block) => _buildContentBlock(block)),
      ],
    );
  }

  Widget _buildContentBlock(ContentBlock block) {
    if (block is ParagraphBlock) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          block.text,
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontSize: 16,
            height: 1.7,
            color: Colors.grey[800],
            fontWeight: block.formatting?['bold'] == true ? FontWeight.bold : FontWeight.normal,
            fontStyle: block.formatting?['italic'] == true ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      );
    }
    
    if (block is StoryBlock) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE57373).withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '❝',
              style: TextStyle(
                fontSize: 24,
                color: Color(0xFFE57373),
                height: 1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                block.content,
                style: TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    if (block is ListBlock) {
      if (block.ordered) {
        // Numbered list
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: block.items.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${entry.key + 1}.',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE57373),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        );
      } else {
        // Bullet list
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: block.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE57373),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        );
      }
    }
    
    if (block is HeadingBlock) {
      return Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Text(
          block.text,
          style: TextStyle(
            fontSize: block.level == 3 ? 18 : 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D2D2D),
          ),
        ),
      );
    }
    
    if (block is CodeBlock) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          block.content,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  void _shareSection(Section section) {
    final textContent = section.blocks.map((block) {
      if (block is ParagraphBlock) return block.text;
      if (block is StoryBlock) return block.content;
      if (block is HeadingBlock) return block.text;
      if (block is ListBlock) return block.items.join('\n');
      if (block is CodeBlock) return block.content;
      return '';
    }).join('\n\n');
    
    final text = '${section.title}\n\n$textContent';
    Share.share(text, subject: 'From ${widget.chapter.title}');
  }
}
