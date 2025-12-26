import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/app_colors.dart';
import '../../../config/constants.dart';
import '../../../data/repositories/user_repository.dart';

/// Splash screen - disguised as "Wellness Guide"
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for splash duration
    await Future.delayed(AppConstants.splashDuration);
    
    if (!mounted) return;
    
    // Check if user setup is complete
    final userRepo = UserRepository();
    final userExists = await userRepo.userExists();
    
    if (userExists) {
      // User already set up - get user and navigate to appropriate home
      final user = await userRepo.getUser();
      
      if (user!.isFemale) {
        Navigator.of(context).pushReplacementNamed('/female-home');
      } else {
        Navigator.of(context).pushReplacementNamed('/male-home');
      }
    } else {
      // New user - start onboarding
      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar color
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.pinkGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Disguised icon - wellness/health theme
              Icon(
                Icons.favorite_rounded,
                size: 100,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appNameDisguised,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Wellness Companion',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
