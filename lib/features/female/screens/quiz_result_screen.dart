import 'package:flutter/material.dart';
import 'package:saathi/routes/app_routes.dart';

import '../../../config/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/repositories/chapter_progress_repository.dart';

/// Quiz result screen showing score and feedback
class QuizResultScreen extends StatelessWidget {
  final Chapter chapter;
  final int score;
  final List<bool> userAnswers;

  const QuizResultScreen({
    super.key,
    required this.chapter,
    required this.score,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final correctCount = _getCorrectCount();
    final totalQuestions = chapter.quizQuestions.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Result icon - always success
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF66BB6A).withOpacity(0.1),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 80,
                        color: Color(0xFF66BB6A),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Result title - always positive
                    const Text(
                      'Great Job!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Score
                    Text(
                      '$score%',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF66BB6A),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Correct answers
                    Text(
                      '$correctCount out of $totalQuestions correct',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Feedback message - always congratulatory
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '🎉 Wonderful progress! Review your answers and mark the chapter complete when you\'re ready to continue.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF2D2D2D),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Fixed bottom buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mark Complete button (primary)
                  CustomButton(
                    onPressed: () async {
                      // Mark chapter as complete
                      final progressRepo = ChapterProgressRepository();
                      final progress =
                          await progressRepo.getChapterProgress(chapter.number);
                      if (progress != null) {
                        await progressRepo.updateProgress(
                          progress.copyWith(
                            completed: true,
                            quizCompleted: true,
                            quizScore: score,
                          ),
                        );
                      }

                      if (context.mounted) {
                        Navigator.popUntil(
                            context,
                            (route) =>
                                route.settings.name == AppRoutes.femaleHome);
                      }
                    },
                    text: 'Mark Chapter Complete',
                  ),

                  const SizedBox(height: 12),

                  // Retry button
                  CustomButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to quiz to retry
                    },
                    text: 'Try Again',
                    isOutlined: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getCorrectCount() {
    int count = 0;
    for (int i = 0; i < userAnswers.length; i++) {
      if (userAnswers[i] == chapter.quizQuestions[i].correctAnswer) {
        count++;
      }
    }
    return count;
  }
}
