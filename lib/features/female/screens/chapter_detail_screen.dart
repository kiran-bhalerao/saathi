import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/models/chapter_progress_model.dart';
import '../../../data/repositories/chapter_progress_repository.dart';
import '../../../data/repositories/content_parser.dart';
import 'chapter_discussion_screen.dart';

/// Chapter detail screen - shows chapter info before reading
class ChapterDetailScreen extends StatefulWidget {
  final int chapterNumber;

  const ChapterDetailScreen({
    super.key,
    required this.chapterNumber,
  });

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  final ContentParser _parser = ContentParser();

  Chapter? _chapter;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChapter();
  }

  Future<void> _loadChapter() async {
    try {
      // Always load chapter in English for the detail screen
      final chapter = await _parser.parseChapter(widget.chapterNumber);
      setState(() {
        _chapter = chapter;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Chapter ${widget.chapterNumber}'),
          backgroundColor: AppColors.primary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading chapter',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final chapter = _chapter!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 1.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back,
                color: AppColors.primary, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline,
                color: AppColors.primary, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChapterDiscussionScreen(chapter: _chapter!),
                ),
              );
            },
            tooltip: 'Discussion',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            // Removed global padding to allow full-width divider
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Divider under app bar
                Container(
                  height: 1,
                  color: Colors.grey[200],
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Minimal Chapter Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'CHAPTER ${chapter.number}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Big Title
                      Text(
                        chapter.title,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1F1F1F),
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        chapter.subtitle,
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.grey[600],
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Stats Row with Dividers
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                                Icons.schedule,
                                '${chapter.estimatedReadMinutes} min',
                                'Read Time'),
                            Container(
                                width: 1, height: 24, color: Colors.grey[300]),
                            _buildStatItem(Icons.style_outlined,
                                '${chapter.sections.length}', 'Sections'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Content Title
                      const Text(
                        'What You\'ll Learn',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sections List (Clean Editorial Style)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: chapter.sections.length,
                        padding: EdgeInsets.zero,
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.grey.withOpacity(0.1),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final section = chapter.sections[index];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Text(
                                  (index + 1).toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary.withOpacity(0.3),
                                    fontFamily: 'monospace',
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    section.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2D2D2D),
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Gradient Fade at bottom for smooth scroll under
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 32,
            right: 32,
            bottom: 32,
            child: CustomButton(
              onPressed: () async {
                // Mark chapter as in progress
                final progressRepo = ChapterProgressRepository();
                final existingProgress =
                    await progressRepo.getChapterProgress(chapter.number);

                if (existingProgress == null) {
                  await progressRepo.updateProgress(
                    ChapterProgress(
                      chapterNumber: chapter.number,
                      completed: false,
                      lastReadAt: DateTime.now(),
                      readingTimeSeconds: 0,
                      quizCompleted: false,
                    ),
                  );
                } else if (!existingProgress.completed) {
                  await progressRepo.updateProgress(
                    existingProgress.copyWith(
                      lastReadAt: DateTime.now(),
                    ),
                  );
                }

                if (context.mounted) {
                  Navigator.of(context).pushNamed(
                    '/chapter-reader',
                    arguments: chapter,
                  );
                }
              },
              text: 'Start Reading',
              icon: Icons.menu_book_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
