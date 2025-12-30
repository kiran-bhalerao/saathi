import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/bluetooth_provider.dart';
import '../../female/widgets/pairing_code_dialog.dart';

/// Shared Partner Connection section
/// Simplified UI: Status Card -> Spacer -> Single Action Button
class PartnerConnectionSection extends StatefulWidget {
  final bool showTitle;

  const PartnerConnectionSection({
    super.key,
    this.showTitle = true,
  });

  @override
  State<PartnerConnectionSection> createState() =>
      _PartnerConnectionSectionState();
}

class _PartnerConnectionSectionState extends State<PartnerConnectionSection> {
  bool _isFemale = false;
  String _maleInputCode = '';

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

  void _showEnterCodeDialog(BuildContext context, BluetoothProvider provider) {
    _maleInputCode = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Partner Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Enter the pairing code shown on your partner\'s device.'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Pairing Code',
                border: OutlineInputBorder(),
                hintText: 'e.g. 123456',
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => _maleInputCode = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_maleInputCode.length >= 4) {
                provider.connectWithCode(_maleInputCode);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connecting to partner...')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showUnpairConfirmation(
      BuildContext context, BluetoothProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpair Device?'),
        content: const Text(
          'This will disconnect and unpair your device. You will need to pair again to communicate.',
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

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section header
            if (widget.showTitle)
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
              margin:
                  EdgeInsets.symmetric(horizontal: widget.showTitle ? 16 : 0),
              padding: const EdgeInsets.all(20),
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
                    _buildInfoRow(Icons.phone_android, 'Partner Device',
                        'Connected Device'),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                        Icons.access_time, 'Last Connected', 'Just now'),
                  ],
                ],
              ),
            ),

            // Use Spacer to push buttons to bottom
            const Spacer(),

            // Action Buttons (Bottom)
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: widget.showTitle ? 16 : 0),
              child: Column(
                children: [
                  // CASE 1: NOT PAIRED -> Show Connect Options
                  if (!provider.isPaired) ...[
                    if (_isFemale)
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          icon: Icons.qr_code,
                          text: 'Generate Pairing Code',
                          onPressed: () async {
                            final code = await provider.generatePairingCode();
                            if (context.mounted) {
                              _showPairingCodeDialog(context, code);
                            }
                          },
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          icon: Icons.input,
                          text: 'Enter Pairing Code',
                          onPressed: () =>
                              _showEnterCodeDialog(context, provider),
                        ),
                      ),
                  ]
                  // CASE 2: PAIRED -> Show Only Unpair
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        icon: Icons.link_off,
                        text: 'Unpair Device',
                        isOutlined: true,
                        onPressed: () =>
                            _showUnpairConfirmation(context, provider),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bottom padding for safe area/spacing
            const SizedBox(height: 16),
          ],
        );
      },
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ',
            style:
                const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
      ],
    );
  }
}
