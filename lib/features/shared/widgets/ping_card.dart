import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';

/// Shared widget for displaying pinged section cards in discussions
/// Used by both female and male users
class PingCard extends StatelessWidget {
  final Map<String, dynamic> ping;
  final VoidCallback? onTap;
  final bool isCurrentUser; // Determines alignment (sender vs receiver)

  const PingCard({
    super.key,
    required this.ping,
    required this.isCurrentUser,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final content = _decodeContent(ping['section_content_json'] as String);
    final sectionTitle = ping['section_title'] as String? ?? 'Shared Quote';

    // Detect if this is a vocabulary term
    final isVocabulary = sectionTitle.toLowerCase() != 'shared quote' &&
        !sectionTitle.toLowerCase().contains('quote');

    final card = Container(
      margin: EdgeInsets.only(
        left: isCurrentUser ? 0 : 12,
        right: isCurrentUser ? 12 : 0,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: isCurrentUser
              ? const Radius.circular(16)
              : const Radius.circular(4),
          bottomRight: isCurrentUser
              ? const Radius.circular(4)
              : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            Border.all(color: AppColors.primary.withOpacity(0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVocabulary
                      ? Icons.auto_stories
                      : Icons.format_quote_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isVocabulary ? 'Vocabulary' : 'Shared Quote',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              // Share icon removed
            ],
          ),
          const SizedBox(height: 12),

          // Content with accent bar
          IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show Title only if it's NOT the generic "Shared Quote" (i.e. Vocabulary Word)
                      if (isVocabulary) ...[
                        Text(
                          sectionTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        content,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          // Vocabulary definition is regular, Quotes are italic
                          fontStyle: isVocabulary
                              ? FontStyle.normal
                              : FontStyle.italic,
                          color: const Color(0xFF4A4A4A),
                        ),
                        maxLines: 8,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              _formatTimestamp(DateTime.parse(ping['pinged_at'] as String)),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );

    // Align based on sender (matching MessageBubble behavior)
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end // Right for current user (sender)
            : MainAxisAlignment.start, // Left for partner (receiver)
        children: [
          SizedBox(
            // Slightly wider constraint for better readability
            width: screenWidth * 0.75,
            child: onTap != null
                ? GestureDetector(onTap: onTap, child: card)
                : card,
          ),
        ],
      ),
    );
  }

  /// Decode JSON-escaped content to remove escape characters
  String _decodeContent(String jsonString) {
    return jsonString
        .replaceAll(r'\"', '"') // Replace \" with "
        .replaceAll(r"\'", "'") // Replace \' with '
        .replaceAll(r'\n', '\n') // Replace \n with actual newline
        .replaceAll(r'\\', '\\'); // Replace \\ with \
  }

  String _formatTimestamp(DateTime dateTime) {
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
