import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/repositories/content_parser.dart';
import '../../../data/repositories/discussion_repository.dart';
import '../../female/screens/chapter_discussion_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadActiveChapters();
  }

  Future<void> _loadActiveChapters() async {
    setState(() => _isLoading = true);
    
    // Get chapters with activity
    final chapterNumbers = await _discussionRepo.getChaptersWithActivity();
    
    // Load full chapter data for each
    final chapters = <Map<String, dynamic>>[];
    for (final item in chapterNumbers) {
      final chapterNum = item['chapter_number'] as int;
      final chapter = await _contentParser.parseChapter(chapterNum);
      
      if (chapter != null) {
        // Get thread to check for activity count
        final thread = await _discussionRepo.getChapterThread(chapterNum);
        
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
    
    setState(() {
      _activeChapters = chapters;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Discussions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          // Settings icon
          IconButton(
            icon: Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _activeChapters.isEmpty
          ? Center(
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
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _activeChapters.length,
              itemBuilder: (context, index) {
                final item = _activeChapters[index];
                final chapter = item['chapter'] as Chapter;
                final count = item['messageCount'] as int;
                
                return _ChapterCard(
                  chapter: chapter,
                  messageCount: count,
                  onTap: () async {
                    // Navigate to shared discussion screen
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChapterDiscussionScreen(chapter: chapter),
                      ),
                    );
                    // Reload after returning
                    _loadActiveChapters();
                  },
                );
              },
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
      margin: const EdgeInsets.only(bottom: 12),
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${chapter.number}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
                    Text(
                      '$messageCount ${messageCount == 1 ? 'item' : 'items'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
                      ),
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
