import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../shared/widgets/partner_connection_section.dart';

/// Dedicated screen for managing partner connection and pairing
/// Wraps the shared PartnerConnectionSection widget
class PartnerConnectionScreen extends StatelessWidget {
  const PartnerConnectionScreen({super.key});

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
      // Use Column + Expanded to allow Spacer in the widget to work
      body: const Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: PartnerConnectionSection(showTitle: false),
            ),
          ),
        ],
      ),
    );
  }
}
