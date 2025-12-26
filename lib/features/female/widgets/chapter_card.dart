import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../data/repositories/chapter_progress_repository.dart';
import '../../../data/models/chapter_progress_model.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = await _progressRepo.getChapterProgress(widget.chapterNumber);
    setState(() {
      _progress = progress;
      _isLoading = false;
    });
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
      'Oral Sex',
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
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted 
                  ? AppColors.success.withOpacity(0.3) 
                  : Colors.grey.withOpacity(0.08),
              width: isCompleted ? 1.5 : 1,
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
                  gradient: isCompleted 
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE57373), Color(0xFFEC407A)],
                        ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isCompleted ? const Color(0xFF66BB6A) : const Color(0xFFE57373)).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 26,
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                        height: 1.2,
                      ),
                    ),
                    if (_progress?.lastReadAt != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isCompleted 
                                  ? AppColors.success 
                                  : const Color(0xFFE57373),
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
                                  : const Color(0xFFE57373),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Arrow icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
