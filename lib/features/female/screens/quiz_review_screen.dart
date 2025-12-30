import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../data/models/chapter_model.dart';

class QuizReviewScreen extends StatelessWidget {
  final Chapter chapter;
  final List<bool> userAnswers;

  const QuizReviewScreen({
    super.key,
    required this.chapter,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // title: Removed as requested
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chapter Title
              Center(
                child: Text(
                  chapter.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Questions List
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: chapter.quizQuestions.length,
                itemBuilder: (context, index) {
                  final question = chapter.quizQuestions[index];
                  final userAnswer = userAnswers[index];
                  final isCorrect = userAnswer == question.correctAnswer;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCorrect
                            ? const Color(0xFF66BB6A).withOpacity(0.3)
                            : const Color(0xFFEF5350).withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? const Color(0xFF66BB6A).withOpacity(0.1)
                                    : const Color(0xFFEF5350).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCorrect
                                    ? Icons.check_rounded
                                    : Icons.close_rounded,
                                size: 16,
                                color: isCorrect
                                    ? const Color(0xFF66BB6A)
                                    : const Color(0xFFEF5350),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                question.question,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D2D2D),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 34),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Your Answer: ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    TextSpan(
                                      text: userAnswer ? 'Yes' : 'No',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isCorrect
                                            ? const Color(0xFF66BB6A)
                                            : const Color(0xFFEF5350),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isCorrect) ...[
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Correct Answer: ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      TextSpan(
                                        text: question.correctAnswer
                                            ? 'Yes'
                                            : 'No',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF66BB6A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
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
      ),
    );
  }
}
