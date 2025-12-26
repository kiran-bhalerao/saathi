import 'package:flutter/material.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/models/sync_models.dart';
import '../../../data/repositories/discussion_repository.dart';
import '../../../data/repositories/ping_repository.dart';
import '../widgets/message_bubble.dart';
import '../widgets/vocabulary_chip_bar.dart';
import '../widgets/chat_input.dart';

/// Chapter Discussion Screen - per-chapter chat
class ChapterDiscussionScreen extends StatefulWidget {
  final Chapter chapter;

  const ChapterDiscussionScreen({
    super.key,
    required this.chapter,
  });

  @override
  State<ChapterDiscussionScreen> createState() => _ChapterDiscussionScreenState();
}

class _ChapterDiscussionScreenState extends State<ChapterDiscussionScreen> {
  final DiscussionRepository _discussionRepo = DiscussionRepository();
  final PingRepository _pingRepo = PingRepository();
  final ScrollController _scrollController = ScrollController();
  
  List<DiscussionMessage> _messages = [];
  List<PingedSection> _pingedSections = [];
  List<String> _vocabularyTerms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _prepareVocabulary();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Load messages
    _messages = await _discussionRepo.getMessagesForChapter(widget.chapter.number);
    
    // Load pinged sections for this chapter
    _pingedSections = await _pingRepo.getPingsByChapter(widget.chapter.number);
    
    setState(() => _isLoading = false);
    
    // Scroll to bottom after loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _prepareVocabulary() {
    // Extract vocabulary terms from chapter
    _vocabularyTerms = widget.chapter.vocabulary
        .map((v) => v.term)
        .toList();
    
    // Add some common terms
    _vocabularyTerms.addAll(['Consent', 'Pleasure', 'Comfort', 'Intimacy']);
  }

  Future<void> _sendMessage(String messageText) async {
    await _discussionRepo.sendMessage(
      chapterNumber: widget.chapter.number,
      sender: 'female', // TODO: Get from user profile
      messageText: messageText,
    );
    
    await _loadData();
  }

  void _insertVocabularyTerm(String term) {
    // Find the ChatInput widget and insert text
    // This will be handled by passing a key to ChatInput
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tap in the text field and use: $term'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
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
        title: Column(
          children: [
            Text(
              widget.chapter.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D2D),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Chapter ${widget.chapter.number}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Pinged sections (if any)
          if (_pingedSections.isNotEmpty)
            Container(
              height: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE57373).withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _pingedSections.length,
                itemBuilder: (context, index) {
                  final section = _pingedSections[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE57373), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.push_pin, size: 14, color: Color(0xFFE57373)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                section.sectionTitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE57373),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            'Shared section',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE57373)))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start a conversation about this chapter',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return MessageBubble(
                            message: message,
                            isCurrentUser: message.sender == 'female',
                          );
                        },
                      ),
          ),

          // Chat input at bottom
          SafeArea(
            child: ChatInput(
              onSendMessage: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
