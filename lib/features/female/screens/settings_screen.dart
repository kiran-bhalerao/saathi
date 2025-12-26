import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

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
      backgroundColor: const Color(0xFFFAF8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE57373), width: 1.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Color(0xFFE57373), size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF2D2D2D),
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Bluetooth Section (moved to top)
          _buildSectionHeader('Bluetooth'),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.bluetooth_connected,
            title: 'Partner Connection',
            subtitle: 'Manage device pairing and sync',
            onTap: () => Navigator.of(context).pushNamed('/partner-connection'),
          ),
          
          const SizedBox(height: 32),
          
          // Data Management Section
          _buildSectionHeader('Data Management'),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.upload_file_outlined,
            title: 'Export Data',
            subtitle: 'Create a backup of your data',
            onTap: _showExportDialog,
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.download_outlined,
            title: 'Import Data',
            subtitle: 'Restore from a backup file',
            onTap: _showImportDialog,
          ),
          
          const SizedBox(height: 32),
          
          // Privacy Section
          _buildSectionHeader('Privacy'),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.delete_outline,
            title: 'Delete All Data',
            subtitle: 'Permanently erase all app data',
            onTap: _showDeleteDialog,
            isDestructive: true,
          ),
          
          const SizedBox(height: 32),
          
          // About Section
          _buildSectionHeader('About'),
          const SizedBox(height: 12),
          _buildInfoTile('App Version', 'v1.0.0'),
          _buildInfoTile('Database', 'Encrypted with SQLCipher'),
          _buildInfoTile('Privacy', '100% Offline - No data collection'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF9E9E9E),
        letterSpacing: 0.5,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDestructive ? const Color(0xFFFF5252) : const Color(0xFFE57373))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive ? const Color(0xFFFF5252) : const Color(0xFFE57373),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF2D2D2D),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
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
      builder: (dialogContext) => _PINVerificationDialog(
        title: 'Export Data',
        message: 'Enter your PIN to verify and export your data',
        hint: 'Remember this PIN! You will need it to import this backup on any device.',
        onConfirm: (pin) async {
          Navigator.pop(dialogContext);
          
          if (!mounted) return;
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
      builder: (dialogContext) => _PINVerificationDialog(
        title: 'Import Data',
        message: 'Enter the PIN that was used to encrypt this backup',
        hint: 'This is the PIN from the device where you created the backup.',
        onConfirm: (pin) async {
          Navigator.pop(dialogContext);
          
          if (!mounted) return;
          
          // Show confirmation dialog before proceeding
          _showImportConfirmDialog(filePath, pin);
        },
      ),
    );
  }

  void _showImportConfirmDialog(String filePath, String pin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 12),
            const Text('Confirm Import'),
          ],
        ),
        content: const Text(
          'This action will override all existing data:\n\n'
          '• Chapter progress\n'
          '• Shared content\n'
          '• Discussion messages\n\n'
          'Your current PIN will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () async {
              Navigator.pop(context);
              
              if (!mounted) return;
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
            child: const Text('Continue'),
          ),
        ],
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
      builder: (dialogContext) => _PINVerificationDialog(
        title: 'Confirm Deletion',
        message: 'Enter your PIN to confirm deletion',
        onConfirm: (pin) async {
          Navigator.pop(dialogContext);
          
          if (!mounted) return;
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
  final String? hint;  // Optional hint message
  final Function(String pin) onConfirm;

  const _PINVerificationDialog({
    required this.title,
    required this.message,
    this.hint,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 24),
          PINInputWidget(
            length: 4,
            onCompleted: _onPINEntered,
            errorMessage: _errorMessage,
          ),
          if (widget.hint != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.hint!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
