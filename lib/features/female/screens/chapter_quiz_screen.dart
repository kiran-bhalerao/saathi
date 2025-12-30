import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/repositories/chapter_progress_repository.dart';
import '../widgets/quiz_card.dart';
import 'quiz_result_screen.dart';

/// Chapter quiz screen with swipeable cards
class ChapterQuizScreen extends StatefulWidget {
  final Chapter chapter;

  const ChapterQuizScreen({
    super.key,
    required this.chapter,
  });

  @override
  State<ChapterQuizScreen> createState() => _ChapterQuizScreenState();
}

class _ChapterQuizScreenState extends State<ChapterQuizScreen> {
  final ChapterProgressRepository _progressRepo = ChapterProgressRepository();

  int _currentQuestionIndex = 0;
  final List<bool> _userAnswers = [];

  void _handleAnswer(bool answer) {
    setState(() {
      _userAnswers.add(answer);
      _currentQuestionIndex++;
    });

    // Check if quiz is complete
    if (_currentQuestionIndex >= widget.chapter.quizQuestions.length) {
      _completeQuiz();
    }
  }

  void _completeQuiz() async {
    // Calculate score
    int correctAnswers = 0;
    for (int i = 0; i < _userAnswers.length; i++) {
      if (_userAnswers[i] == widget.chapter.quizQuestions[i].correctAnswer) {
        correctAnswers++;
      }
    }

    final score =
        (correctAnswers / widget.chapter.quizQuestions.length * 100).round();

    // Save quiz score only - don't mark chapter as complete yet
    final progress =
        await _progressRepo.getChapterProgress(widget.chapter.number);
    if (progress != null) {
      await _progressRepo.updateProgress(
        progress.copyWith(
          quizCompleted: true,
          quizScore: score,
          // Don't set completed here - user must explicitly mark complete
        ),
      );
    }

    // Navigate to results
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(
            chapter: widget.chapter,
            score: score,
            userAnswers: _userAnswers,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.chapter.quizQuestions;

    if (questions.isEmpty) {
      return Scaffold(
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
        body: const Center(
          child: Text('No quiz available for this chapter'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
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
        title: Column(
          children: [
            const Text(
              'Chapter Quiz',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D2D),
              ),
            ),
            Text(
              widget.chapter.title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  Text(
                    '${(((_currentQuestionIndex) / questions.length) * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Linear progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _currentQuestionIndex / questions.length,
                  backgroundColor: const Color(0xFFE0E0E0),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Quiz card stack
            Expanded(
              child: Stack(
                children: [
                  // Show next card in background for depth effect
                  if (_currentQuestionIndex < questions.length - 1)
                    Positioned.fill(
                      child: Center(
                        child: Transform.scale(
                          scale: 0.92,
                          child: Opacity(
                            opacity: 0.3,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.85,
                              height: 320,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Current card
                  if (_currentQuestionIndex < questions.length)
                    QuizCard(
                      key: ValueKey(_currentQuestionIndex),
                      question: questions[_currentQuestionIndex],
                      questionNumber: _currentQuestionIndex + 1,
                      totalQuestions: questions.length,
                      onAnswer: _handleAnswer,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Minimal swipe instruction
            Text(
              'Swipe left for NO or right for YES',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                letterSpacing: 0.3,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
