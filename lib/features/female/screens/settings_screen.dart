import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../shared/widgets/quick_exit_button.dart';
import '../../../shared/widgets/pin_input_widget.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../core/services/data_export_service.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../core/database/database_service.dart';

/// Settings screen - app configuration and data management
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DataExportService _exportService = DataExportService();
  final UserRepository _userRepo = UserRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [QuickExitButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Data Management Section
          _buildSectionHeader('Data Management'),
          _buildSettingCard(
            icon: Icons.upload_file,
            title: 'Export Data',
            subtitle: 'Create a backup of your data',
            onTap: _showExportDialog,
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.download,
            title: 'Import Data',
            subtitle: 'Restore from a backup file',
            onTap: _showImportDialog,
          ),
          
          const SizedBox(height: 32),
          
          // Privacy Section
          _buildSectionHeader('Privacy'),
          _buildSettingCard(
            icon: Icons.delete_forever,
            title: 'Delete All Data',
            subtitle: 'Permanently erase all app data',
            onTap: _showDeleteDialog,
            isDestructive: true,
          ),
          
          const SizedBox(height: 32),
          
          // About Section
          _buildSectionHeader('About'),
          _buildInfoTile('App Version', 'v1.0.0'),
          _buildInfoTile('Database', 'Encrypted with SQLCipher'),
          _buildInfoTile('Privacy', '100% Offline - No data collection'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDestructive ? AppColors.error : AppColors.primary)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppColors.error : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  // ========== Export Dialog ==========
  
  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => _PINVerificationDialog(
        title: 'Export Data',
        message: 'Enter your PIN to export your data',
        onConfirm: (pin) async {
          Navigator.pop(context);
          LoadingOverlay.show(context, message: 'Exporting data...');
          
          try {
            final exportPath = await _exportService.exportDatabase(pin);
            
            if (!mounted) return;
            LoadingOverlay.hide(context);
            
            if (exportPath != null) {
              _showExportSuccessDialog(exportPath);
            }
          } catch (e) {
            if (!mounted) return;
            LoadingOverlay.hide(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Export failed: ${e.toString()}')),
            );
          }
        },
      ),
    );
  }

  void _showExportSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✓ Export Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your data has been exported successfully.'),
            const SizedBox(height: 16),
            Text(
              'File: ${filePath.split('/').last}',
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _exportService.shareExportedFile(filePath);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  // ========== Import Dialog ==========
  
  void _showImportDialog() async {
    final filePath = await _exportService.pickImportFile();
    
    if (filePath == null) return;
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => _PINVerificationDialog(
        title: 'Import Data',
        message: 'Enter your PIN to import data\n\nWARNING: This will replace all current data!',
        onConfirm: (pin) async {
          Navigator.pop(context);
          LoadingOverlay.show(context, message: 'Importing data...');
          
          try {
            await _exportService.importDatabase(filePath, pin);
            
            if (!mounted) return;
            LoadingOverlay.hide(context);
            
            _showImportSuccessDialog();
          } catch (e) {
            if (!mounted) return;
            LoadingOverlay.hide(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Import failed: ${e.toString()}')),
            );
          }
        },
      ),
    );
  }

  void _showImportSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('✓ Import Successful'),
        content: const Text(
          'Data restored successfully!\n\n'
          'Please restart the app for changes to take effect.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Close settings
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ========== Delete Dialog ==========
  
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Delete All Data'),
        content: const Text(
          'This will permanently delete:\n\n'
          '• All chapter progress\n'
          '• All shared content\n'
          '• All settings\n\n'
          'This action CANNOT be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteWithPIN();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteWithPIN() {
    showDialog(
      context: context,
      builder: (context) => _PINVerificationDialog(
        title: 'Confirm Deletion',
        message: 'Enter your PIN to confirm deletion',
        onConfirm: (pin) async {
          Navigator.pop(context);
          LoadingOverlay.show(context, message: 'Deleting data...');
          
          try {
            await DatabaseService.instance.deleteDatabase();
            
            if (!mounted) return;
            LoadingOverlay.hide(context);
            
            // Navigate to splash (restart flow)
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
              (route) => false,
            );
          } catch (e) {
            if (!mounted) return;
            LoadingOverlay.hide(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Delete failed: ${e.toString()}')),
            );
          }
        },
      ),
    );
  }
}

// ========== PIN Verification Dialog (Reusable) ==========

class _PINVerificationDialog extends StatefulWidget {
  final String title;
  final String message;
  final Function(String pin) onConfirm;

  const _PINVerificationDialog({
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  State<_PINVerificationDialog> createState() => _PINVerificationDialogState();
}

class _PINVerificationDialogState extends State<_PINVerificationDialog> {
  String? _errorMessage;

  void _onPINEntered(String pin) async {
    widget.onConfirm(pin);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.message),
          const SizedBox(height: 24),
          PINInputWidget(
            length: 4,
            onCompleted: _onPINEntered,
            errorMessage: _errorMessage,
          ),
        ],
      ),
    );
  }
}
