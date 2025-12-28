import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../core/security/pin_manager.dart';
import '../../shared/widgets/pin_input_widget.dart';

/// Wraps the app to provide PIN lock functionality on resume
class AppLockWrapper extends StatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> with WidgetsBindingObserver {
  final PINManager _pinManager = PINManager();
  bool _isLocked = false;
  bool _isPinSet = false;
  bool _isLoading = true;
  bool _wasPaused = false; // Track if app was previously in background

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPinStatus(isLaunch: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App truly went to background (hidden)
      _wasPaused = true;
    } else if (state == AppLifecycleState.resumed) {
      // App came to foreground
      if (_wasPaused) {
        // Only trigger lock if we are coming from a PAUSED State (background)
        // This prevents locking on simple INACTIVE states (notification shade, system dialogs)
        _checkPinStatus(isLaunch: false);
        _wasPaused = false; // Reset flag
      }
    }
  }

  Future<void> _checkPinStatus({required bool isLaunch}) async {
    try {
      final hasPin = await _pinManager.isPINConfigured();
      setState(() {
        _isPinSet = hasPin;
        _isLoading = false;
        
        // Only lock on resume, not on initial launch
        // This allows users to complete onboarding first
        if (hasPin && !isLaunch) {
           _isLocked = true;
        }
      });
    } catch (e) {
      debugPrint('Error checking PIN status: $e');
      setState(() => _isLoading = false);
    }
  }

  void _unlock() {
    setState(() {
      _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Lock Overlay with its own Overlay support for TextFields
        if (_isLocked && _isPinSet)
          Positioned.fill(
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => _LockScreen(
                    onUnlock: _unlock,
                    pinManager: _pinManager,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  final PINManager pinManager;

  const _LockScreen({
    required this.onUnlock,
    required this.pinManager,
  });

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  String? _errorMessage;
  bool _isValidating = false;
  final PINInputController _pinInputController = PINInputController();

  void _onPinEntered(String pin) async {
    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final isValid = await widget.pinManager.verifyPIN(pin);
      if (isValid) {
        // Unlock
        widget.onUnlock();
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Incorrect PIN';
            _isValidating = false;
          });
          // Clear the PIN fields after a brief delay
          Future.delayed(const Duration(milliseconds: 500), () {
            _pinInputController.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error verifying PIN';
          _isValidating = false;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          _pinInputController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, // Allow keyboard to resize content
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your App PIN to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    PINInputWidget(
                      controller: _pinInputController,
                      length: 4,
                      onCompleted: _onPinEntered,
                      errorMessage: _errorMessage,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    if (_isValidating)
                      const CircularProgressIndicator(color: AppColors.primary),
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
