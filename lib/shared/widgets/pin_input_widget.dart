import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';

/// Controller for PIN input widget
class PINInputController {
  VoidCallback? _clearCallback;

  void clear() {
    _clearCallback?.call();
  }

  void _attach(VoidCallback callback) {
    _clearCallback = callback;
  }

  void _detach() {
    _clearCallback = null;
  }
}

/// PIN Input Size variants
enum PinInputSize {
  small,
  large,
}

/// PIN input widget for setup and verification
class PINInputWidget extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final String? errorMessage;
  final bool isObscured;
  final PINInputController? controller;
  final PinInputSize size;

  const PINInputWidget({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.errorMessage,
    this.isObscured = true,
    this.controller,
    this.size = PinInputSize.large,
  });

  @override
  State<PINInputWidget> createState() => _PINInputWidgetState();
}

class _PINInputWidgetState extends State<PINInputWidget> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();

    // Attach controller
    widget.controller?._attach(() => clear());

    for (int i = 0; i < widget.length; i++) {
      _controllers.add(TextEditingController());
      final focusNode = FocusNode();
      _focusNodes.add(focusNode);

      // Auto-focus first field on init
      if (i == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
        });
      }
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();

    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length > 1) {
      // Paste - fill all fields
      _fillFromPaste(value);
      return;
    }

    if (value.isNotEmpty) {
      // Single digit entered - move to next field
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field filled - unfocus and check if complete
        _focusNodes[index].unfocus();
      }

      // Check if all fields are now filled
      _checkAndSubmit();
    }
  }

  void _checkAndSubmit() {
    final pin = _controllers.map((c) => c.text).join();
    if (pin.length == widget.length) {
      widget.onCompleted(pin);
    }
  }

  void _fillFromPaste(String value) {
    final digits =
        value.replaceAll(RegExp(r'\D'), '').substring(0, widget.length);
    for (int i = 0; i < digits.length; i++) {
      _controllers[i].text = digits[i];
    }
    if (digits.length == widget.length) {
      _focusNodes.last.unfocus();
      _checkAndSubmit();
    }
  }

  void clear() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    // Dimensions based on size variant
    final isSmall = widget.size == PinInputSize.small;
    final double boxWidth = isSmall ? 50 : 64;
    final double boxHeight = isSmall ? 60 : 76;
    final double horizontalPadding = isSmall ? 5 : 8;
    final double fontSize = isSmall ? 24 : 32;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            final isLast = index == widget.length - 1;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: SizedBox(
                width: boxWidth,
                height: boxHeight,
                child: KeyboardListener(
                  focusNode:
                      FocusNode(), // Use a separate FocusNode for listener to avoid conflict? No, wrapper needs it. But usually wrapping TextField works.
                  // Actually, TextField consumes keys?
                  // Providing a new FocusNode() to KeyboardListener works as long as it's part of the focus chain?
                  // Better: Wrap TextField in RawKeyboardListener/KeyboardListener but use the TextField's focus node?
                  // But TextField manages its own focus node.
                  // Standard flutter pattern: Wrap TextField.
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace) {
                      // Backspace pressed
                      if (_controllers[index].text.isEmpty && index > 0) {
                        // Field is empty, move to previous
                        _focusNodes[index - 1].requestFocus();
                        // Note: We do NOT clear the previous field automatically per user request
                      }
                    }
                  },
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textInputAction:
                        isLast ? TextInputAction.done : TextInputAction.next,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    cursorColor: AppColors.primary,
                    cursorHeight: fontSize * 0.9,
                    maxLength: 1,
                    obscureText: widget.isObscured,
                    style: AppTextStyles.pinInput.copyWith(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: widget.errorMessage != null
                              ? AppColors.error
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    onChanged: (value) => _onChanged(value, index),
                  ),
                ),
              ),
            );
          }),
        ),
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.errorMessage!,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
