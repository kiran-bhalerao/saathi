import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

/// Quick-exit button for all screens - instant navigation to decoy screen
class QuickExitButton extends StatelessWidget {
  const QuickExitButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: const Icon(Icons.exit_to_app),
        tooltip: 'Quick Exit',
        onPressed: () => _performQuickExit(context),
        color: AppColors.primary,
      ),
    );
  }

  void _performQuickExit(BuildContext context) {
    // Navigate instantly to decoy screen (no animation)
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DecoyScreen(),
        transitionDuration: Duration.zero, // Instant
      ),
      (route) => false, // Clear entire stack
    );
    
    // TODO: Clear sensitive data from memory (providers)
    // TODO: Lock app for next launch
  }
}

/// Decoy screen - neutral wellness content
class DecoyScreen extends StatelessWidget {
  const DecoyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness Guide'),
        automaticallyImplyLeading: false, // No back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.favorite,
              size: 100,
              color: Colors.pink[200],
            ),
            const SizedBox(height: 24),
            const Text(
              'Daily Wellness Tips',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildTip('💧', 'Hydration', 'Drink 8 glasses of water daily'),
            _buildTip('😴', 'Sleep', 'Get 7-8 hours of quality sleep'),
            _buildTip('🏃', 'Exercise', '30 minutes of activity daily'),
            _buildTip('🥗', 'Nutrition', 'Eat balanced, colorful meals'),
            _buildTip('🧘', 'Mindfulness', 'Practice 10 minutes of meditation'),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String emoji, String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
