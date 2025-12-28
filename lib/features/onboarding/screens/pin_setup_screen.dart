import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../core/security/pin_manager.dart';
import '../../../shared/widgets/pin_input_widget.dart';

/// PIN setup screen - create new PIN
class PINSetupScreen extends StatefulWidget {
  const PINSetupScreen({super.key});

  @override
  State<PINSetupScreen> createState() => _PINSetupScreenState();
}

class _PINSetupScreenState extends State<PINSetupScreen> {
  final PINManager _pinManager = PINManager();
  final GlobalKey _devLockKey = GlobalKey();
  final GlobalKey _pinKey = GlobalKey();
  final GlobalKey _confirmKey = GlobalKey();

  String? _enteredPIN;
  String? _errorMessage;
  bool _isLoading = false;

  // Three-step flow: devLock -> create -> confirm
  String _currentStep = 'devLock'; // devLock, create, confirm

  /// Generate dev lock PIN from current time (simple mental math)
  /// Rule: Time HHMM → Take 3rd digit, 2nd digit, 4th digit, 1st digit
  /// Example: 10:26 → 1026 → 0261 (3rd=2, 2nd=0, 4th=6, 1st=1)
  String _generateDevLockPIN() {
    final now = DateTime.now();

    // Get time in 12-hour format (easier to calculate mentally)
    final hour12 =
        now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute;

    // Format as HHMM string (pad with zeros)
    final hourStr = hour12.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr$minuteStr';

    // Apply simple swap: positions [2,1,3,0] (3rd, 2nd, 4th, 1st)
    // Add +1 to the 1st digit (with wrapping: 9→0)
    final firstDigit = int.parse(timeStr[0]);
    final modifiedFirst = (firstDigit + 1) % 10;
    final pin = '${timeStr[2]}${timeStr[1]}${timeStr[3]}$modifiedFirst';
    return pin;
  }

  /// Validate dev lock PIN
  bool _validateDevLock(String pin) {
    final expectedPIN = _generateDevLockPIN();

    // Debug: Show current time and expected PIN
    final now = DateTime.now();
    final hour12 =
        now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    debugPrint(
        '🔒 Time: ${hour12.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} → PIN: $expectedPIN');

    return pin == expectedPIN;
  }

  void _onPINEntered(String pin) {
    if (_currentStep == 'devLock') {
      // Dev Lock verification
      if (_validateDevLock(pin)) {
        setState(() {
          _currentStep = 'create';
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Invalid developer code. Please try again.';
        });
      }
    } else if (_currentStep == 'create') {
      // First PIN entry
      setState(() {
        _enteredPIN = pin;
        _currentStep = 'confirm';
        _errorMessage = null;
      });
    } else {
      // Confirmation step
      if (pin == _enteredPIN) {
        _setupPIN(pin);
      } else {
        setState(() {
          _errorMessage = 'PINs do not match. Please try again.';
          _currentStep = 'create';
          _enteredPIN = null;
        });
      }
    }
  }

  Future<void> _setupPIN(String pin) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _pinManager.setupPIN(pin);

      if (!mounted) return;

      // Navigate to gender selection
      Navigator.of(context).pushReplacementNamed('/gender-selection');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _currentStep = 'create';
        _enteredPIN = null;
      });
    }
  }

  void _goBack() {
    if (_currentStep == 'confirm') {
      setState(() {
        _currentStep = 'create';
        _enteredPIN = null;
        _errorMessage = null;
      });
    } else if (_currentStep == 'create') {
      setState(() {
        _currentStep = 'devLock';
        _errorMessage = null;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine title and description based on step
    String title;
    String description;

    if (_currentStep == 'devLock') {
      title = 'Developer Access';
      description = 'Enter developer code to continue';
    } else if (_currentStep == 'create') {
      title = 'Create a PIN';
      description = 'Create a 4-6 digit PIN to secure your data';
    } else {
      title = 'Confirm Your PIN';
      description = 'Enter your PIN again to confirm';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, // Allow keyboard to resize content
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE57373), width: 1.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back,
                color: Color(0xFFE57373), size: 16),
          ),
          onPressed: _goBack,
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32.0, vertical: 24.0),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Lock icon
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.05),
                        ),
                        child: Center(
                          child: Icon(
                            _currentStep == 'devLock'
                                ? Icons.code
                                : Icons.lock_outline,
                            size: 70,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // PIN input - different key for each step
                    if (_currentStep == 'devLock')
                      PINInputWidget(
                        key: _devLockKey,
                        length: 4,
                        onCompleted: _onPINEntered,
                        errorMessage: _errorMessage,
                      )
                    else if (_currentStep == 'create')
                      PINInputWidget(
                        key: _pinKey,
                        length: 4,
                        onCompleted: _onPINEntered,
                        errorMessage: _errorMessage,
                      )
                    else
                      PINInputWidget(
                        key: _confirmKey,
                        length: _enteredPIN?.length ?? 4,
                        onCompleted: _onPINEntered,
                        errorMessage: _errorMessage,
                      ),

                    const SizedBox(height: 32),

                    // Security note - show only for create/confirm steps
                    if (_currentStep != 'devLock')
                      const Text(
                        'Your PIN is encrypted and stored securely',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),

                    const Spacer(flex: 3),

                    if (_isLoading)
                      const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
