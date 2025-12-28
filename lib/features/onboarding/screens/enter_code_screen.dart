import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/bluetooth_provider.dart';
import '../../../data/models/bluetooth_enums.dart';
import '../../../config/app_colors.dart';
import '../../../shared/widgets/pin_input_widget.dart';

/// Male code entry screen - BLOCKING until paired
class EnterCodeScreen extends StatefulWidget {
  const EnterCodeScreen({super.key});

  @override
  State<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen> {
  String? _errorMessage;
  bool _isConnecting = false;

  Future<void> _onCodeEntered(String code) async {
    setState(() => _isConnecting = true);

    final provider = context.read<BluetoothProvider>();
    final success = await provider.connectWithCode(code);

    setState(() => _isConnecting = false);

    if (success) {
      // Navigate to Male Home after successful pairing
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/male-home');
      }
    } else {
      // Show error
      if (mounted) {
        setState(() {
          _errorMessage = provider.errorMessage ?? 'Connection failed';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F8),
      resizeToAvoidBottomInset: true, // Allow keyboard to resize content
      appBar: AppBar(
        title: const Text('Connect to Partner'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    const Icon(
                      Icons.lock_outline,
                      size: 60,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Enter the code shown on\nyour partner\'s phone',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    
                    // Use shared PIN input widget
                    PINInputWidget(
                      length: 4,
                      onCompleted: _onCodeEntered,
                      errorMessage: _errorMessage,
                      isObscured: false, // Show the code digits
                    ),
                    
                    const Spacer(),
                    
                    // Connection status text
                    Consumer<BluetoothProvider>(
                      builder: (context, provider, child) {
                        if (provider.connectionStatus == ConnectionStatus.scanning) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Searching for partner device...',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        } else if (provider.connectionStatus == ConnectionStatus.connecting) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Connecting...',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    if (_isConnecting)
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
