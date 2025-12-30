import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../data/models/chapter_progress_model.dart';
import '../../../data/repositories/chapter_progress_repository.dart';

/// Reusable chapter card widget (following DRY principle)
class ChapterCard extends StatefulWidget {
  final int chapterNumber;
  final VoidCallback onTap;

  const ChapterCard({
    super.key,
    required this.chapterNumber,
    required this.onTap,
  });

  @override
  State<ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<ChapterCard> {
  final ChapterProgressRepository _progressRepo = ChapterProgressRepository();
  ChapterProgress? _progress;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void didUpdateWidget(ChapterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload progress if chapter number changed or after navigation
    if (oldWidget.chapterNumber != widget.chapterNumber) {
      _loadProgress();
    }
  }

  Future<void> _loadProgress() async {
    final progress =
        await _progressRepo.getChapterProgress(widget.chapterNumber);
    if (mounted) {
      setState(() {
        _progress = progress;
      });
    }
  }

  Future<bool> _isChapterLocked() async {
    // Chapter 1 is always unlocked
    if (widget.chapterNumber == 1) return false;

    // Check if previous chapter is completed
    final previousProgress =
        await _progressRepo.getChapterProgress(widget.chapterNumber - 1);
    return previousProgress?.completed != true;
  }

  // Chapter titles (static for now)
  String get _chapterTitle {
    const titles = [
      'The Partnership',
      'The Female Garden',
      'The Baby Maker',
      'The Magic Button',
      'Ladder to the Stars',
      'The Orgasm Gap',
      'Making It Work',
      'Using Your Mouth',
      'The Back Door',
      'Spicing It Up',
      'The Feedback Loop',
      'Aftercare & Connection',
    ];

    return titles[widget.chapterNumber - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _progress?.completed == true;

    return FutureBuilder<bool>(
      future: _isChapterLocked(),
      builder: (context, snapshot) {
        final isLocked = snapshot.data ?? false;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLocked ? null : widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Opacity(
              opacity: isLocked ? 0.5 : 1.0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Chapter number circle with gradient
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: isLocked
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.grey[400]!, Colors.grey[500]!],
                              )
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.primary, Color(0xFFEC407A)],
                              ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isLocked
                                    ? Colors.grey[400]!
                                    : AppColors.primary)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: isLocked
                            ? const Icon(
                                Icons.lock_rounded,
                                color: Colors.white,
                                size: 24,
                              )
                            : Text(
                                widget.chapterNumber.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Chapter info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chapter ${widget.chapterNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _chapterTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isLocked
                                  ? Colors.grey[500]
                                  : const Color(0xFF2D2D2D),
                              height: 1.2,
                            ),
                          ),
                          if (_progress?.lastReadAt != null && !isLocked) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? AppColors.success
                                        : AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isCompleted ? 'Completed' : 'In progress',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isCompleted
                                        ? AppColors.success
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Arrow icon or lock indicator
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLocked
                            ? Icons.lock_rounded
                            : Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
