import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class GuessInputBox extends StatefulWidget {
  final void Function(String guess) onSubmit;
  final bool enabled;

  const GuessInputBox({
    super.key,
    required this.onSubmit,
    this.enabled = true,
  });

  @override
  State<GuessInputBox> createState() => _GuessInputBoxState();
}

class _GuessInputBoxState extends State<GuessInputBox> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    widget.onSubmit(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: widget.enabled,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'Type player name...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 56,
          width: 56,
          child: ElevatedButton(
            onPressed: widget.enabled ? _submit : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: AppTheme.neonGreen,
            ),
            child: const Icon(Icons.send_rounded),
          ),
        ),
      ],
    );
  }
}
