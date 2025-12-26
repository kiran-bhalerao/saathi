import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../providers/bluetooth_provider.dart';
import '../../../data/models/bluetooth_enums.dart';
import '../../../data/repositories/user_repository.dart';
import 'pairing_code_dialog.dart';

/// Partner Connection section for Settings screen
/// Shows pairing status, device info, and connection controls
class PartnerConnectionSection extends StatefulWidget {
  const PartnerConnectionSection({super.key});

  @override
  State<PartnerConnectionSection> createState() => _PartnerConnectionSectionState();
}

class _PartnerConnectionSectionState extends State<PartnerConnectionSection> {
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

  String _getTimeSince(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Text(
                'Partner Connection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Status card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getStatusText(provider),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(provider),
                        ),
                      ),
                    ],
                  ),

                  if (provider.isPaired) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Device info (placeholder - will show actual device ID in later phases)
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_android,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Partner Device',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Last connected info
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Last connected: ${_getTimeSince(null)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // View Pairing Code button (Female only)
                  if (_isFemale && provider.pairingCode != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showPairingCodeDialog(context, provider.pairingCode!),
                        icon: const Icon(Icons.qr_code),
                        label: const Text('View Pairing Code'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),

                  if (_isFemale && provider.pairingCode != null)
                    const SizedBox(height: 12),

                  // Reconnect/Disconnect button
                  if (provider.isPaired)
                    SizedBox(
                      width: double.infinity,
                      child: provider.isConnected
                          ? OutlinedButton.icon(
                              onPressed: () => provider.disconnect(),
                              icon: const Icon(Icons.bluetooth_disabled),
                              label: const Text('Disconnect'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: Colors.orange),
                                foregroundColor: Colors.orange,
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () => provider.reconnect(),
                              icon: const Icon(Icons.bluetooth_searching),
                              label: const Text('Reconnect'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                    ),

                  if (provider.isPaired) const SizedBox(height: 12),

                  // Unpair button
                  if (provider.isPaired)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showUnpairConfirmation(context, provider),
                        icon: const Icon(Icons.link_off),
                        label: const Text('Unpair Device'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
