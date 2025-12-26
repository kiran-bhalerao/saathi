import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../data/repositories/ping_repository.dart';
import '../../../data/models/sync_models.dart';
import 'dart:convert';
import '../../../data/models/chapter_model.dart';

/// Male home screen - view content shared by partner
class MaleHomeScreen extends StatefulWidget {
  const MaleHomeScreen({super.key});

  @override
  State<MaleHomeScreen> createState() => _MaleHomeScreenState();
}

class _MaleHomeScreenState extends State<MaleHomeScreen> {
  final PingRepository _pingRepo = PingRepository();
  List<PingedSection> _pings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPings();
  }

  Future<void> _loadPings() async {
    try {
      final pings = await _pingRepo.getAllPings();
      setState(() {
        _pings = pings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared with You'),

      ),
      body: _pings.isEmpty
          ? const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No Content Shared Yet',
              message:
                  'Your partner hasn\'t shared any sections with you.\n\nWhen they do, you\'ll see them here.',
            )
          : RefreshIndicator(
              onRefresh: _loadPings,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _pings.length,
                itemBuilder: (context, index) {
                  final ping = _pings[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildPingCard(ping),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildPingCard(PingedSection ping) {
    return InkWell(
      onTap: () => _viewPing(ping),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ping.readByPartner ? Colors.white : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ping.readByPartner ? AppColors.divider : AppColors.primary.withOpacity(0.3),
            width: ping.readByPartner ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter number badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Chapter ${ping.chapterNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (!ping.readByPartner)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Section title
            Text(
              ping.sectionTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            
            // Timestamp
            Text(
              'Shared ${_formatTimestamp(ping.pingedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            
            // Read/View button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewPing(ping),
                  icon: Icon(
                    ping.readByPartner ? Icons.visibility : Icons.visibility_outlined,
                    size: 18,
                  ),
                  label: Text(ping.readByPartner ? 'View Again' : 'Read Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewPing(PingedSection ping) {
    // Mark as read
    if (!ping.readByPartner) {
      _pingRepo.markAsRead(ping.id);
      setState(() {
        ping = PingedSection(
          id: ping.id,
          chapterNumber: ping.chapterNumber,
          sectionId: ping.sectionId,
          sectionTitle: ping.sectionTitle,
          sectionContentJson: ping.sectionContentJson,
          pingedAt: ping.pingedAt,
          synced: ping.synced,
          readByPartner: true,
          readAt: DateTime.now(),
        );
      });
    }

    // Navigate to content view
    Navigator.of(context).pushNamed(
      '/male-ping-view',
      arguments: ping,
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
