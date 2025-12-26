import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../data/models/sync_models.dart';

/// Message bubble widget for chat display
class MessageBubble extends StatelessWidget {
  final DiscussionMessage message;
  final bool isCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Use SizedBox to force specific width
          SizedBox(
            width: screenWidth * 0.8, // Fixed 80% width
            child: Container(
              margin: EdgeInsets.only(
                left: isCurrentUser ? 0 : 12,
                right: isCurrentUser ? 12 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? AppColors.primary
                    : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isCurrentUser ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isCurrentUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMessageText(),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.sentAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isCurrentUser ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageText() {
    final text = message.messageText;
    
    // Check if message has bold markdown (**text**)
    if (text.contains('**')) {
      final parts = <TextSpan>[];
      final regex = RegExp(r'\*\*(.*?)\*\*');
      int lastIndex = 0;
      
      for (final match in regex.allMatches(text)) {
        // Add text before match
        if (match.start > lastIndex) {
          parts.add(TextSpan(
            text: text.substring(lastIndex, match.start),
          ));
        }
        
        // Add bold text
        parts.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ));
        
        lastIndex = match.end;
      }
      
      // Add remaining text
      if (lastIndex < text.length) {
        parts.add(TextSpan(
          text: text.substring(lastIndex),
        ));
      }
      
      return RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: isCurrentUser ? Colors.white : Colors.grey[800],
          ),
          children: parts,
        ),
      );
    } else {
      // Regular text
      return Text(
        text,
        style: TextStyle(
          fontSize: 15,
          color: isCurrentUser ? Colors.white : Colors.grey[800],
          height: 1.4,
        ),
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
