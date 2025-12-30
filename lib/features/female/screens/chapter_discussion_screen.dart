import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_colors.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/models/sync_models.dart';
import '../../../data/repositories/discussion_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/bluetooth_provider.dart';
import '../../shared/widgets/ping_card.dart';
import '../../shared/widgets/ping_content_modal.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';
import '../widgets/vocabulary_chip_bar.dart';

/// Chapter Discussion Screen - per-chapter chat
class ChapterDiscussionScreen extends StatefulWidget {
  final Chapter chapter;

  const ChapterDiscussionScreen({
    super.key,
    required this.chapter,
  });

  @override
  State<ChapterDiscussionScreen> createState() =>
      _ChapterDiscussionScreenState();
}

class _ChapterDiscussionScreenState extends State<ChapterDiscussionScreen> {
  final DiscussionRepository _discussionRepo = DiscussionRepository();
  final UserRepository _userRepo = UserRepository();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  List<Map<String, dynamic>> _thread = []; // Merged messages + pings
  List<String> _vocabularyTerms = [];
  bool _isLoading = true;
  String _currentUserType = 'female';
  Timer? _refreshTimer;
  int _lastThreadLength = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _prepareVocabulary();
    _loadUserType();

    // Periodic refresh to check for new messages from partner
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshThread();
    });
  }

  Future<void> _loadUserType() async {
    final user = await _userRepo.getUser();
    if (user != null) {
      setState(() => _currentUserType = user.userType);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load merged thread (messages + pings chronologically)
    _thread = await _discussionRepo.getChapterThread(widget.chapter.number);
    _lastThreadLength = _thread.length;

    setState(() => _isLoading = false);

    // Scroll to bottom after loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  /// Silent background refresh to check for new messages
  Future<void> _refreshThread() async {
    if (!mounted) return;

    final newThread =
        await _discussionRepo.getChapterThread(widget.chapter.number);

    // Only update if thread has new items
    if (newThread.length != _lastThreadLength) {
      setState(() {
        _thread = newThread;
        _lastThreadLength = newThread.length;
      });

      // Auto-scroll to bottom if new messages arrived
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _prepareVocabulary() {
    // Extract vocabulary terms from chapter
    _vocabularyTerms = widget.chapter.vocabulary.map((v) => v.term).toList();
  }

  Future<void> _sendMessage(String messageText) async {
    if (messageText.trim().isEmpty) return;

    await _discussionRepo.sendMessage(
      chapterNumber: widget.chapter.number,
      sender: _currentUserType,
      messageText: messageText,
    );

    // Auto-sync message immediately if connected
    if (mounted) {
      final provider = Provider.of<BluetoothProvider>(context, listen: false);
      if (provider.isConnected) {
        provider.syncNow();
      }
    }

    _textController.clear();
    await _loadData();
  }

  void _insertVocabularyTerm(String term) {
    // Try to get the vocabulary definition
    String message;
    try {
      final vocab = widget.chapter.vocabulary.firstWhere(
        (v) => v.term == term,
      );
      // Send with term on first line (will be bolded) and definition below
      message = '**$term**\n${vocab.definition}';
    } catch (e) {
      // No definition found, just send the term in bold
      message = '**$term**';
    }

    _sendMessage(message);
  }

  // Helper getters for dynamic theming
  Color get _themeColor =>
      _currentUserType == 'female' ? AppColors.primary : AppColors.primaryMale;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

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
              border: Border.all(color: _themeColor, width: 1.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back, color: _themeColor, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.chapter.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Vocabulary chips - ONLY for female users
          if (_currentUserType == 'female' && _vocabularyTerms.isNotEmpty)
            VocabularyChipBar(
              terms: _vocabularyTerms,
              onTermSelected: _insertVocabularyTerm,
            ),

          // Thread (messages + pinged sections)
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _themeColor))
                : _thread.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text(
                              'No messages yet',
                              style: TextStyle(
                                  fontSize: 16, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Start a conversation about this chapter',
                              style: TextStyle(
                                  fontSize: 14, color: AppColors.textLight),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(
                            top: 12, bottom: 12), // Only top/bottom padding
                        itemCount: _thread.length,
                        itemBuilder: (context, index) {
                          final item = _thread[index];
                          final type = item['type'] as String;

                          if (type == 'message') {
                            final message = item['data'] as DiscussionMessage;
                            return MessageBubble(
                              message: message,
                              isCurrentUser: message.sender == _currentUserType,
                              // Pass user type to message bubble for theming
                              userType: _currentUserType,
                            );
                          } else {
                            // Pinged section - use shared PingCard
                            final ping = item['data'] as Map<String, dynamic>;
                            return PingCard(
                              ping: ping,
                              // If current user is female, she is the sender (Right aligned)
                              // If male, he (current user) is the receiver?
                              // Wait, 'isCurrentUser' in PingCard usually implies alignment.
                              // If I am female and I sent it -> Right.
                              // If I am male (receiver) -> Left.
                              // PingCard logic assumes 'female' sends pings.
                              // So: isCurrentUser = (sender == myType).
                              // Pings are sent by Female. So sender is always 'female'.
                              // If I am 'female', isCurrentUser = true.
                              // If I am 'male', isCurrentUser = false.
                              isCurrentUser: _currentUserType == 'female',
                              // Add tap handler for male to view full content
                              onTap: _currentUserType == 'male'
                                  ? () => _showPingContent(ping)
                                  : null,
                            );
                          }
                        },
                      ),
          ),

          // Chat input at bottom
          SafeArea(
            child: ChatInput(
              textController: _textController,
              onSendMessage: _sendMessage,
              // Pass theme color
              themeColor: _themeColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Show ping content in modal (for male users)
  void _showPingContent(Map<String, dynamic> ping) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PingContentModal(
        sectionTitle: ping['section_title'] as String? ?? 'Shared Content',
        content: ping['section_content_json'] as String,
      ),
    );
  }
}
