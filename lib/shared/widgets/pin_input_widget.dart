import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';

/// PIN input widget for setup and verification
class PINInputWidget extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final String? errorMessage;
  final bool isObscured;

  const PINInputWidget({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.errorMessage,
    this.isObscured = true,
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
    for (int i = 0; i < widget.length; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isEmpty) {
      // Backspace - move to previous field
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      return;
    }

    if (value.length > 1) {
      // Paste - fill all fields
      _fillFromPaste(value);
      return;
    }

    // Single digit entered
    if (index < widget.length - 1) {
      // Move to next field
      _focusNodes[index + 1].requestFocus();
    } else {
      // Last field - submit PIN
      _focusNodes[index].unfocus();
      _submitPIN();
    }
  }

  void _fillFromPaste(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '').substring(0, widget.length);
    for (int i = 0; i < digits.length; i++) {
      _controllers[i].text = digits[i];
    }
    if (digits.length == widget.length) {
      _focusNodes.last.unfocus();
      _submitPIN();
    }
  }

  void _submitPIN() {
    final pin = _controllers.map((c) => c.text).join();
    if (pin.length == widget.length) {
      widget.onCompleted(pin);
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 50,
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  obscureText: widget.isObscured,
                  style: AppTextStyles.pinInput,
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: widget.errorMessage != null
                            ? AppColors.error
                            : AppColors.divider,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) => _onChanged(value, index),
                ),
              ),
            );
          }),
        ),
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.errorMessage!,
            style: TextStyle(
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
