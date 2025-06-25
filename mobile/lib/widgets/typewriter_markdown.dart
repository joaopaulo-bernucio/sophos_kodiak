import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import 'markdown_renderer.dart';

class TypewriterMarkdown extends StatefulWidget {
  final String text;
  final bool isUser;
  final Duration speed;
  final VoidCallback? onComplete;

  const TypewriterMarkdown({
    super.key,
    required this.text,
    this.isUser = false,
    this.speed = const Duration(milliseconds: 30),
    this.onComplete,
  });

  @override
  State<TypewriterMarkdown> createState() => _TypewriterMarkdownState();
}

class _TypewriterMarkdownState extends State<TypewriterMarkdown> {
  late String _displayText;
  Timer? _timer;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _displayText = '';
    _startTyping();
  }

  void _startTyping() {
    int index = 0;
    _timer = Timer.periodic(widget.speed, (timer) {
      if (index < widget.text.length) {
        if (mounted) {
          setState(() {
            _displayText += widget.text[index++];
          });
        }
      } else {
        timer.cancel();
        _isCompleted = true;
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownRenderer(
      text: _displayText,
      isUser: widget.isUser,
      selectable: _isCompleted, // Só permite seleção quando a animação termina
    );
  }
}

class AnimatedTypingCursor extends StatefulWidget {
  final TextStyle? textStyle;
  final Color? cursorColor;

  const AnimatedTypingCursor({super.key, this.textStyle, this.cursorColor});

  @override
  State<AnimatedTypingCursor> createState() => _AnimatedTypingCursorState();
}

class _AnimatedTypingCursorState extends State<AnimatedTypingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Text(
            '|',
            style:
                widget.textStyle?.copyWith(
                  color: widget.cursorColor ?? AppColors.textSecondary,
                ) ??
                TextStyle(color: widget.cursorColor ?? AppColors.textSecondary),
          ),
        );
      },
    );
  }
}
