import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../config/constants.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/repositories/content_parser.dart';
import '../../../data/repositories/discussion_repository.dart';
import '../../../providers/bluetooth_provider.dart';
import '../../../data/models/bluetooth_enums.dart';
import '../../female/screens/chapter_discussion_screen.dart';
import '../../shared/widgets/bluetooth_status_icon.dart';

/// Male Home Screen - Shows chapters with active discussions or shared pings
class MaleHomeScreen extends StatefulWidget {
  const MaleHomeScreen({super.key});

  @override
  State<MaleHomeScreen> createState() => _MaleHomeScreenState();
}

class _MaleHomeScreenState extends State<MaleHomeScreen> {
  final ContentParser _contentParser = ContentParser();
  final DiscussionRepository _discussionRepo = DiscussionRepository();
  
  List<Map<String, dynamic>> _activeChapters = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  int _lastTotalMessages = 0;

  @override
  void initState() {
    super.initState();
    _loadActiveChapters();
    
    // Periodic refresh every 3 seconds to detect new messages
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshActiveChapters();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveChapters() async {
    setState(() => _isLoading = true);
    await _fetchChapters();
    setState(() => _isLoading = false);
  }

  /// Silent background refresh
  Future<void> _refreshActiveChapters() async {
    if (!mounted) return;
    
    final oldTotal = _lastTotalMessages;
    await _fetchChapters();
    
    // Only setState if total message count changed
    if (_lastTotalMessages != oldTotal) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _fetchChapters() async {
    // Get chapters with activity
    final chapterNumbers = await _discussionRepo.getChaptersWithActivity();
    
    // Load full chapter data for each
    final chapters = <Map<String, dynamic>>[];
    int totalMsgs = 0;

    for (final item in chapterNumbers) {
      final chapterNum = item['chapter_number'] as int;
      final chapter = await _contentParser.parseChapter(chapterNum);
      
      if (chapter != null) {
        // Get thread to check for activity count
        final thread = await _discussionRepo.getChapterThread(chapterNum);
        totalMsgs += thread.length;
        
        chapters.add({
          'chapter': chapter,
          'messageCount': thread.length,
          'lastActivity': thread.isNotEmpty 
            ? thread.last['timestamp'] as DateTime
            : DateTime.now(),
        });
      }
    }
    
    // Sort by last activity (most recent first)
    chapters.sort((a, b) => 
      (b['lastActivity'] as DateTime).compareTo(a['lastActivity'] as DateTime)
    );
    
    _activeChapters = chapters;
    _lastTotalMessages = totalMsgs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F8),
      body: RefreshIndicator(
        onRefresh: _loadActiveChapters,
        child: CustomScrollView(
          slivers: [
            // Modern gradient header (blue theme for Male)
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: const Color(0xFF64B5F6),
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                // Bluetooth connection icon (New Widget)
                const BluetoothStatusIcon(),
                
                const SizedBox(width: 2),
                // Settings icon
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.of(context).pushNamed('/settings'),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF64B5F6),
                        Color(0xFF42A5F5),
                        Color(0xFF2196F3),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -40,
                        right: -40,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 40,
                        left: -20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      // Content
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Discussions',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Stay connected 💬',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Activity summary card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildActivityCard(),
              ),
            ),
            
            // Chapter list header
            if (_activeChapters.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF64B5F6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Active Chapters',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Chapter list OR empty state
            if (_isLoading)
              SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (_activeChapters.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 24),
                      Text(
                        'No discussions yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          'Your partner hasn\'t shared any content',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _activeChapters[index];
                      final chapter = item['chapter'] as Chapter;
                      final count = item['messageCount'] as int;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChapterCard(
                          chapter: chapter,
                          messageCount: count,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChapterDiscussionScreen(chapter: chapter),
                              ),
                            );
                            // Reload after returning
                            _loadActiveChapters();
                          },
                        ),
                      );
                    },
                    childCount: _activeChapters.length,
                  ),
                ),
              ),
            
            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    final totalMessages = _activeChapters.fold<int>(
      0,
      (sum, item) => sum + (item['messageCount'] as int),
    );
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF64B5F6).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: Color(0xFF64B5F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Discussions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalMessages == 0
                      ? 'No new updates'
                      : '$totalMessages ${totalMessages == 1 ? 'message' : 'messages'} in ${_activeChapters.length} ${_activeChapters.length == 1 ? 'chapter' : 'chapters'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF64B5F6), Color(0xFF2196F3)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_activeChapters.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final Chapter chapter;
  final int messageCount;
  final VoidCallback onTap;

  const _ChapterCard({
    required this.chapter,
    required this.messageCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Chapter icon/number
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF64B5F6), Color(0xFF2196F3)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${chapter.number}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Chapter info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.message_rounded, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '$messageCount ${messageCount == 1 ? 'item' : 'items'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
