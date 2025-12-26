import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';

import '../../../data/models/sync_models.dart';
import '../../../data/models/chapter_model.dart';
import 'dart:convert';

/// Male ping viewer - view specific pinged section content
class MalePingViewScreen extends StatelessWidget {
  final PingedSection ping;

  const MalePingViewScreen({
    super.key,
    required this.ping,
  });

  @override
  Widget build(BuildContext context) {
    // Parse content from JSON
    final contentData = jsonDecode(ping.sectionContentJson) as List;
    final blocks = contentData
        .map((json) => ContentBlock.fromJson(json as Map<String, dynamic>))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Chapter ${ping.chapterNumber}'),

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shared badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.share,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Shared by your partner',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Section title
            Text(
              ping.sectionTitle,
              style: AppTextStyles.sectionHeading,
            ),
            const SizedBox(height: 16),
            
            // Render content blocks
            ...blocks.map((block) => _buildContentBlock(context, block)),
            
            const SizedBox(height: 48),
            
            // Info message
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Why was this shared?',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your partner thought this section would be helpful for you to read. '
                    'Take your time to understand it, and feel free to discuss it together.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentBlock(BuildContext context, ContentBlock block) {
    if (block is ParagraphBlock) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          block.text,
          style: AppTextStyles.bodyText,
          textAlign: TextAlign.justify,
        ),
      );
    }
    
    if (block is ListBlock) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: block.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final prefix = block.ordered ? '${index + 1}. ' : '• ';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prefix, style: AppTextStyles.bodyText),
                  Expanded(
                    child: Text(item, style: AppTextStyles.bodyText),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }
    
    if (block is CodeBlock) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            block.content,
            style: AppTextStyles.monoText,
          ),
        ),
      );
    }
    
    if (block is HeadingBlock) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Text(
          block.text,
          style: block.level == 3
              ? AppTextStyles.sectionHeading.copyWith(fontSize: 18)
              : AppTextStyles.sectionHeading.copyWith(fontSize: 16),
        ),
      );
    }
    
    if (block is StoryBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.format_quote,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  block.content,
                  style: AppTextStyles.bodyText.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}
