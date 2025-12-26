import 'package:flutter/material.dart';
import '../../../data/models/chapter_model.dart';

/// Swipeable quiz card widget
class QuizCard extends StatefulWidget {
  final QuizQuestion question;
  final int questionNumber;
  final int totalQuestions;
  final Function(bool answer) onAnswer;

  const QuizCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.onAnswer,
  });

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;
  
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    // Determine if swipe was significant enough
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3;

    if (_dragOffset.dx.abs() > threshold) {
      // Swipe was significant - answer the question
      final answer = _dragOffset.dx > 0; // Right = Yes, Left = No
      
      // Animate card off screen
      _slideAnimation = Tween<Offset>(
        begin: Offset(_dragOffset.dx / screenWidth, _dragOffset.dy / MediaQuery.of(context).size.height),
        end: Offset(_dragOffset.dx > 0 ? 2 : -2, 0),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      
      _rotateAnimation = Tween<double>(
        begin: _dragOffset.dx / screenWidth * 0.3,
        end: _dragOffset.dx > 0 ? 0.5 : -0.5,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));

      _controller.forward().then((_) {
        widget.onAnswer(answer);
        _controller.reset();
      });
    } else {
      // Snap back to center
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
  }

  void _answerQuestion(bool answer) {
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(answer ? 2 : -2, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: answer ? 0.3 : -0.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward().then((_) {
      widget.onAnswer(answer);
      _controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rotation = _isDragging ? _dragOffset.dx / screenWidth * 0.15 : _rotateAnimation.value;
    final offsetX = _isDragging ? _dragOffset.dx : _slideAnimation.value.dx * screenWidth;
    final offsetY = _isDragging ? _dragOffset.dy * 0.5 : _slideAnimation.value.dy * MediaQuery.of(context).size.height;

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Center(
        child: Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: Transform.rotate(
            angle: rotation,
            child: Container(
              width: screenWidth * 0.85,
              height: 320,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.question.question,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
