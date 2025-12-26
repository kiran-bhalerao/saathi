import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../providers/bluetooth_provider.dart';
import '../../../data/models/bluetooth_enums.dart';
import '../../../data/repositories/user_repository.dart';
import '../widgets/pairing_code_dialog.dart';

/// Dedicated screen for managing partner connection and pairing
class PartnerConnectionScreen extends StatefulWidget {
  const PartnerConnectionScreen({super.key});

  @override
  State<PartnerConnectionScreen> createState() => _PartnerConnectionScreenState();
}

class _PartnerConnectionScreenState extends State<PartnerConnectionScreen> {
  bool _isFemale = false;

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final user = await UserRepository().getUser();
    if (mounted) {
      setState(() {
        _isFemale = user?.userType == 'female';
      });
    }
  }

  void _showPairingCodeDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) => PairingCodeDialog(pairingCode: code),
    );
  }

  void _showUnpairConfirmation(BuildContext context, BluetoothProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpair Device?'),
        content: const Text(
          'This will remove the pairing with your partner. You will need to pair again to sync data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await provider.unpairDevice();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Device unpaired successfully')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Unpair'),
          ),
        ],
      ),
    );
  }

  String _getStatusText(BluetoothProvider provider) {
    if (!provider.isPaired) return 'Not Paired';
    if (provider.isConnected) return 'Connected';
    return 'Paired (Disconnected)';
  }

  IconData _getStatusIcon(BluetoothProvider provider) {
    if (!provider.isPaired) return Icons.link_off;
    if (provider.isConnected) return Icons.check_circle;
    return Icons.bluetooth;
  }

  Color _getStatusColor(BluetoothProvider provider) {
    if (!provider.isPaired) return Colors.grey;
    if (provider.isConnected) return Colors.green;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Partner Connection',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Consumer<BluetoothProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status row
                            Row(
                              children: [
                                Icon(
                                  _getStatusIcon(provider),
                                  color: _getStatusColor(provider),
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _getStatusText(provider),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(provider),
                                  ),
                                ),
                              ],
                            ),

                            if (provider.isPaired) ...[
                              const SizedBox(height: 20),
                              const Divider(height: 1),
                              const SizedBox(height: 20),

                              // Device info
                              _buildInfoRow(
                                Icons.phone_android,
                                'Partner Device',
                                'Connected Device',
                              ),

                              const SizedBox(height: 16),

                              // Last connected
                              _buildInfoRow(
                                Icons.access_time,
                                'Last Connected',
                                'Never', // TODO: Implement actual timestamp
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                     if (_isFemale && provider.pairingCode != null)
                        const SizedBox(height: 12),

                      if (provider.isPaired)
                        _buildActionButton(
                          icon: provider.isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_searching,
                          label: provider.isConnected ? 'Disconnect' : 'Reconnect',
                          color: provider.isConnected ? Colors.orange : AppColors.primary,
                          onPressed: () => provider.isConnected
                              ? provider.disconnect()
                              : provider.reconnect(),
                          outlined: !provider.isConnected,
                        ),

                      if (provider.isPaired) const SizedBox(height: 12),

                      if (provider.isPaired)
                        _buildActionButton(
                          icon: Icons.link_off,
                          label: 'Unpair Device',
                          color: AppColors.error,
                          onPressed: () => _showUnpairConfirmation(context, provider),
                          outlined: true,
                        ),
                      
                      // Re-pair option for female users who are already paired
                      if (provider.isPaired && _isFemale) ...[
                        const SizedBox(height: 24),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Need to pair with a different device?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _handleGenerateCode(context, provider, isRepair: true),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Re-pair with New Device'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(color: Colors.orange),
                                    foregroundColor: Colors.orange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Generate button at bottom for unpaired female users
              if (!provider.isPaired && _isFemale)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildActionButton(
                    icon: Icons.add_link,
                    label: 'Generate Pairing Code',
                    color: AppColors.primary,
                    onPressed: () => _handleGenerateCode(context, provider, isRepair: false),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Handle generating/regenerating pairing code
  Future<void> _handleGenerateCode(
    BuildContext context,
    BluetoothProvider provider, {
    required bool isRepair,
  }) async {
    // If re-pairing (already paired), show confirmation
    if (isRepair) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Re-pair Device?'),
          content: const Text(
            'This will disconnect your current partner and generate a new pairing code. '
            'Your partner will need to pair again using the new code.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Unpair current device
      await provider.unpairDevice();
    }

    // Generate new code
    final code = await provider.generatePairingCode();
    
    // Show code dialog
    if (context.mounted) {
      _showPairingCodeDialog(context, code);
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: color),
            foregroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
