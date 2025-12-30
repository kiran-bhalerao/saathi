import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_colors.dart';
import '../../../data/models/bluetooth_enums.dart';
import '../../../providers/bluetooth_provider.dart';

/// Female pairing code screen - shows 4-digit code during onboarding
class PairingCodeScreen extends StatefulWidget {
  const PairingCodeScreen({super.key});

  @override
  State<PairingCodeScreen> createState() => _PairingCodeScreenState();
}

class _PairingCodeScreenState extends State<PairingCodeScreen> {
  String? _pairingCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  Future<void> _generateCode() async {
    // Wait for the next frame to ensure context is available
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final provider = context.read<BluetoothProvider>();
    final code = await provider.generatePairingCode();

    if (mounted) {
      setState(() {
        _pairingCode = code;
        _isLoading = false;
      });
    }
  }

  void _skipPairing() {
    // Navigate to Home screen
    Navigator.pushReplacementNamed(context, '/female-home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pair with Partner',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              const Spacer(),

              // Bluetooth Icon
              // Bluetooth Icon
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.bluetooth_connected_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Title
              const Text(
                'Share this code with\nyour partner',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.4,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Pairing Code Display
              _isLoading
                  ? const SizedBox(
                      height: 80,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 64,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFFDADA),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFEBEB),
                                  blurRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _pairingCode != null &&
                                        _pairingCode!.length > index
                                    ? _pairingCode![index]
                                    : '',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontFamily: 'Poppins', // Or app default
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

              const SizedBox(height: 48),

              // Waiting indicator
              Consumer<BluetoothProvider>(
                builder: (context, provider, child) {
                  if (provider.pairingStatus == PairingStatus.paired) {
                    // Auto-navigate to home
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/female-home');
                      }
                    });
                  }

                  return provider.pairingStatus == PairingStatus.pairing
                      ? const Column(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Waiting for partner to connect...',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink();
                },
              ),

              const Spacer(),
              const Spacer(),

              // Skip button
              TextButton(
                onPressed: _skipPairing,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Skip for Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                '(You can pair later from Settings)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
