import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';

/// Vocabulary chip bar for quick text insertion
class VocabularyChipBar extends StatelessWidget {
  final List<String> terms;
  final Function(String) onTermSelected;

  const VocabularyChipBar({
    super.key,
    required this.terms,
    required this.onTermSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (terms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: terms.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                terms[index],
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.primary, width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              onPressed: () => onTermSelected(terms[index]),
            ),
          );
        },
      ),
    );
  }
}
