import 'package:flutter/material.dart';

/// Vocabulary chip bar for quick text insertion
class VocabularyChipBar extends StatelessWidget {
  final List<String> vocabularyTerms;
  final Function(String) onChipTapped;

  const VocabularyChipBar({
    super.key,
    required this.vocabularyTerms,
    required this.onChipTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (vocabularyTerms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: vocabularyTerms.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              label: Text(
                vocabularyTerms[index],
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFE57373),
                ),
              ),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE57373), width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              onPressed: () => onChipTapped(vocabularyTerms[index]),
            ),
          );
        },
      ),
    );
  }
}
