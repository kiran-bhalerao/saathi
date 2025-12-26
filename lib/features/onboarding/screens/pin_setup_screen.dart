import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../shared/widgets/pin_input_widget.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/security/pin_manager.dart';

/// PIN setup screen - create new PIN
class PINSetupScreen extends StatefulWidget {
  const PINSetupScreen({super.key});

  @override
  State<PINSetupScreen> createState() => _PINSetupScreenState();
}

class _PINSetupScreenState extends State<PINSetupScreen> {
  final PINManager _pinManager = PINManager();
  final GlobalKey _pinKey = GlobalKey();
  final GlobalKey _confirmKey = GlobalKey();
  
  String? _enteredPIN;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isConfirmStep = false;

  void _onPINEntered(String pin) {
    if (!_isConfirmStep) {
      // First PIN entry
      setState(() {
        _enteredPIN = pin;
        _isConfirmStep = true;
        _errorMessage = null;
      });
    } else {
      // Confirmation step
      if (pin == _enteredPIN) {
        _setupPIN(pin);
      } else {
        setState(() {
          _errorMessage = 'PINs do not match. Please try again.';
          _isConfirmStep = false;
          _enteredPIN = null;
        });
        
        // Note: Can't clear fields without state access
        // Will auto-clear on rebuild
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
        _isConfirmStep = false;
        _enteredPIN = null;
      });
      
      // Note: Can't clear fields without state access
      // Will auto-clear on rebuild
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create PIN'),
        leading: !_isConfirmStep
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isConfirmStep = false;
                    _enteredPIN = null;
                    _errorMessage = null;
                  });
                },
              ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Lock icon
              Icon(
                Icons.lock_outline,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                _isConfirmStep ? 'Confirm Your PIN' : 'Create a PIN',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                _isConfirmStep
                    ? 'Enter your PIN again to confirm'
                    : 'Create a 4-6 digit PIN to secure your data',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // PIN input
              if (!_isConfirmStep)
                PINInputWidget(
                  key: _pinKey,
                  length: 4, // Default 4 digits
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
              
              const SizedBox(height: 24),
              
              // Security note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your PIN is encrypted and stored securely. Never share it with anyone.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
