import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/models/chapter_progress_model.dart';
import '../../../data/repositories/chapter_progress_repository.dart';
import '../../../data/repositories/ping_repository.dart';
import '../../../providers/bluetooth_provider.dart';
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
  final PingRepository _pingRepo = PingRepository();
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
      quizCompleted: false,
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

  void _showShareConfirmation(String selectedText) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share with Partner?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This will share the selected text with your partner so you can discuss it together.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _shareWithPartner(selectedText);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE57373),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareWithPartner(String text) async {
    try {
      // Generate a unique section ID for the shared text
      final sectionId = 'shared_${DateTime.now().millisecondsSinceEpoch}';
      
      await _pingRepo.pingSection(
        chapterNumber: widget.chapter.number,
        sectionId: sectionId,
        sectionTitle: 'Shared Quote',
        sectionContentJson: text,
      );
      
      // Auto-sync immediately if connected
      if (mounted) {
        final provider = Provider.of<BluetoothProvider>(context, listen: false);
        if (provider.isConnected) {
          provider.syncNow();
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shared with your partner! 💕'),
            backgroundColor: Color(0xFF66BB6A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
        // Section header (removed share button)
        Text(
          section.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),
        
        // Section content
        ...section.blocks.map((block) => _buildContentBlock(block)),
      ],
    );
  }

  Widget _buildContentBlock(ContentBlock block) {
    // Only text blocks are selectable for sharing
    if (block is ParagraphBlock) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SelectableText(
          block.text,
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontSize: 16,
            height: 1.7,
            color: Colors.grey[800],
            fontWeight: block.formatting?['bold'] == true ? FontWeight.bold : FontWeight.normal,
            fontStyle: block.formatting?['italic'] == true ? FontStyle.italic : FontStyle.normal,
          ),
          contextMenuBuilder: (context, editableTextState) {
            final textSelection = editableTextState.textEditingValue.selection;
            if (textSelection.isCollapsed) {
              return const SizedBox.shrink();
            }
            
            final selectedText = editableTextState.textEditingValue.text.substring(
              textSelection.start,
              textSelection.end,
            );
            
            return AdaptiveTextSelectionToolbar(
              anchors: editableTextState.contextMenuAnchors,
              children: [
                TextSelectionToolbarTextButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  onPressed: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showShareConfirmation(selectedText);
                    });
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.share, size: 18, color: Color(0xFFE57373)),
                      SizedBox(width: 6),
                      Text(
                        'Share',
                        style: TextStyle(
                          color: Color(0xFFE57373),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    
    // Story blocks
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
              child: SelectableText(
                block.content,
                style: TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                  color: Colors.grey[700],
                ),
                contextMenuBuilder: (context, editableTextState) {
                  final textSelection = editableTextState.textEditingValue.selection;
                  if (textSelection.isCollapsed) return const SizedBox.shrink();
                  
                  final selectedText = editableTextState.textEditingValue.text.substring(
                    textSelection.start, textSelection.end
                  );
                  
                  return AdaptiveTextSelectionToolbar(
                    anchors: editableTextState.contextMenuAnchors,
                    children: [
                      TextSelectionToolbarTextButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        onPressed: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _showShareConfirmation(selectedText);
                          });
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.share, size: 18, color: Color(0xFFE57373)),
                            SizedBox(width: 6),
                            Text(
                              'Share',
                              style: TextStyle(
                                color: Color(0xFFE57373),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
    
    // Lists
    if (block is ListBlock) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: block.items.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (block.ordered)
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
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE57373),
                      shape: BoxShape.circle,
                    ),
                  ),
                SizedBox(width: (block.ordered) ? 8 : 12),
                Expanded(
                  child: SelectableText(
                    entry.value,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.grey[800],
                    ),
                    contextMenuBuilder: (context, editableTextState) {
                      final textSelection = editableTextState.textEditingValue.selection;
                      if (textSelection.isCollapsed) return const SizedBox.shrink();
                      
                      final selectedText = editableTextState.textEditingValue.text.substring(
                        textSelection.start, textSelection.end
                      );
                      
                      return AdaptiveTextSelectionToolbar(
                        anchors: editableTextState.contextMenuAnchors,
                        children: [
                          TextSelectionToolbarTextButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            onPressed: () {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _showShareConfirmation(selectedText);
                              });
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.share, size: 18, color: Color(0xFFE57373)),
                                SizedBox(width: 6),
                                Text(
                                  'Share',
                                  style: TextStyle(
                                    color: Color(0xFFE57373),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      );
    }
    
    // Headings
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
}
