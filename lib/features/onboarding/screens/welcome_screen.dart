import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';

/// Welcome screen - introduces the app purpose
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Icon
              Icon(
                Icons.favorite_rounded,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Welcome to Saathi',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Your Companion for a Better Relationship',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Description
              Text(
                'Saathi helps married couples learn and communicate about '
                'intimate health topics in a safe, private, and culturally '
                'sensitive way.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Privacy note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '100% Private & Offline\nNo internet required, your data stays on your device',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Get Started button
              CustomButton(
                text: 'Get Started',
                onPressed: () {
                  Navigator.of(context).pushNamed('/pin-setup');
                },
                width: double.infinity,
              ),
              const SizedBox(height: 16),
              
              // Privacy policy link
              TextButton(
                onPressed: () {
                  // TODO: Show privacy policy
                },
                child: const Text('Privacy Policy'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
