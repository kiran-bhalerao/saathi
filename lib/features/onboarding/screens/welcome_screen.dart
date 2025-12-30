import 'package:flutter/material.dart';
import 'package:saathi/core/widgets/custom_button.dart';

import '../../../config/app_colors.dart';

/// Welcome screen - introduces the app purpose
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Illustration/Icon
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.05),
                ),
                child: const Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Title
              const Text(
                'Welcome to Saathi',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Learn and communicate about intimate health topics in a safe, private, and culturally sensitive way.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.6,
                    letterSpacing: 0.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 3),

              // Privacy message
              const Text(
                '100% Private & Offline',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              // Get Started button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/pin-setup');
                  },
                  text: "Get Started",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
