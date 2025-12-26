import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

/// Chat input widget with send button
class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final TextEditingController? textController;  // Optional external controller
  final VoidCallback? onShareSection;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.textController,
    this.onShareSection,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.textController ?? TextEditingController();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    // Only dispose if we created the controller
    if (widget.textController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _sendMessage() {
    if (_hasText) {
      widget.onSendMessage(_controller.text.trim());
      _controller.clear();
    }
  }

  void insertText(String text) {
    final currentText = _controller.text;
    final selection = _controller.selection;
    
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: selection.start + text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFF8F8F8),
      child: Row(
        children: [
          // Text input
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF2D2D2D),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Send button
          Material(
            color: const Color(0xFFE57373),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: _hasText ? _sendMessage : null,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
