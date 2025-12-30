import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../core/security/pin_manager.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

/// Gender selection screen - choose between Female and Male user type
class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  State<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  String? _selectedGender;
  bool _isLoading = false;

  void _selectGender(String gender) {
    setState(() {
      _selectedGender = gender;
    });
  }

  Future<void> _continue() async {
    if (_selectedGender == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Save user profile to database
      final userRepo = UserRepository();
      final pinCreds = await PINManager().getPINCredentials();

      final user = UserModel(
        userType: _selectedGender!,
        pinHash: pinCreds['hash']!,
        pinSalt: pinCreds['salt']!,
        createdAt: DateTime.now(),
      );

      await userRepo.createUser(user);

      if (!mounted) return;

      // Navigate to pairing screens based on gender
      if (_selectedGender == 'female') {
        // Female: Show pairing code screen (can skip)
        Navigator.of(context).pushReplacementNamed('/pairing-code');
      } else {
        // Male: Enter code screen (blocking until paired)
        Navigator.of(context).pushReplacementNamed('/enter-code');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F9),
      appBar: AppBar(
        title: const Text('Select Your Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),

              // Title
              Text(
                'Who will use this app?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Female option
              _GenderCard(
                icon: Icons.person,
                title: 'Female',
                description: 'Full access to all chapters and features',
                isSelected: _selectedGender == 'female',
                onTap: () => _selectGender('female'),
              ),
              const SizedBox(height: 16),

              // Male option
              _GenderCard(
                icon: Icons.person_outline,
                title: 'Male',
                description: 'View content shared by your partner',
                isSelected: _selectedGender == 'male',
                onTap: () => _selectGender('male'),
              ),

              const SizedBox(height: 32),

              // Info note
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'This helps us customize your experience.\nYou can pair with your partner later.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Continue',
                  onPressed: _selectedGender != null ? _continue : null,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable gender selection card
class _GenderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      // Scale slightly when selected? Maybe too complex for simple fix.
      // Just shadow and border.
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Circle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFFFFF0F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withOpacity(0.8),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
