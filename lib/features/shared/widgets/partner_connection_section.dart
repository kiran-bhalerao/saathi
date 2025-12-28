import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
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
  State<PartnerConnectionSection> createState() => _PartnerConnectionSectionState();
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
            const Text('Enter the pairing code shown on your partner\'s device.'),
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

  void _showUnpairConfirmation(BuildContext context, BluetoothProvider provider) {
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
              margin: EdgeInsets.symmetric(horizontal: widget.showTitle ? 16 : 0),
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
                    _buildInfoRow(Icons.phone_android, 'Partner Device', 'Connected Device'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.access_time, 'Last Connected', 'Just now'),
                  ],
                ],
              ),
            ),

            // Use Spacer to push buttons to bottom
            const Spacer(),

            // Action Buttons (Bottom)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.showTitle ? 16 : 0),
              child: Column(
                children: [
                  // CASE 1: NOT PAIRED -> Show Connect Options
                  if (!provider.isPaired) ...[
                    if (_isFemale)
                      _buildActionButton(
                        icon: Icons.qr_code,
                        label: 'Generate Pairing Code',
                        color: AppColors.primary,
                        onPressed: () async {
                           final code = await provider.generatePairingCode();
                           if (context.mounted) _showPairingCodeDialog(context, code);
                        },
                      )
                    else
                      _buildActionButton(
                        icon: Icons.input,
                        label: 'Enter Pairing Code',
                        color: AppColors.primary,
                        onPressed: () => _showEnterCodeDialog(context, provider),
                      ),
                  ] 
                  // CASE 2: PAIRED -> Show Only Unpair (and maybe Disconnect if needed, but user said "just unpair")
                  else ...[
                    // We'll keep Disconnect as a secondary outlined button if connected
                    // But to strictly follow "just unpair", I'll remove it or make it very subtle? 
                    // User said: "if there is pair, just give unpair button".
                    // I will strictly follow this. Only Unpair.
                    // Wait, if I unpair, I lose connection code. What if I just want to disconnect temporarily?
                    // The user said "we will allow only one connection per user". 
                    // I will provide ONLY Unpair button as requested.
                    
                    _buildActionButton(
                      icon: Icons.link_off,
                      label: 'Unpair Device',
                      color: AppColors.error,
                      onPressed: () => _showUnpairConfirmation(context, provider),
                      outlined: true, // Red outline looks good
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
        Text('$label: ', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
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
    final style = outlined 
      ? OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16), // Taller button
          side: BorderSide(color: color),
          foregroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      : ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16), // Taller button
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );

    return SizedBox(
      width: double.infinity,
      child: outlined 
        ? OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label), style: style)
        : ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label), style: style),
    );
  }
}
