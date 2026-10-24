import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/tokens.dart';
import '../../ui/layout.dart';

/// Six 64px boxes split 3 + 3 by a dash, per Figma node 705:4602. Filled boxes get the purple
/// border; empty ones keep the light border.
class CodeInput extends StatefulWidget {
  const CodeInput({super.key, required this.onChanged, this.onComplete});

  final ValueChanged<String> onChanged;

  /// Called when Enter is pressed in any box.
  final VoidCallback? onComplete;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  static const _length = 6;

  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _nodes = List.generate(_length, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _length; i++) {
      _nodes[i].onKeyEvent = (_, event) => _onKey(i, event);
      _nodes[i].addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(_controllers.map((c) => c.text).join());

  void _onChanged(int i, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    // Pasting the whole code into one box fills them all.
    if (digits.length > 1) {
      final code = digits.length > _length ? digits.substring(0, _length) : digits;
      for (var j = 0; j < _length; j++) {
        _controllers[j].text = j < code.length ? code[j] : '';
      }
      _nodes[code.length.clamp(0, _length - 1)].requestFocus();
    } else {
      _controllers[i].text = digits;
      if (digits.isNotEmpty && i < _length - 1) _nodes[i + 1].requestFocus();
    }
    setState(() {});
    _emit();
  }

  KeyEventResult _onKey(int i, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace && _controllers[i].text.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final gap = context.dvw(6, 1.2, 12);

    Widget box(int i) {
      final filled = _controllers[i].text.isNotEmpty;
      final color = filled || _nodes[i].hasFocus ? Dak.cta : Dak.heading;
      return Flexible(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 64),
          child: AspectRatio(
            aspectRatio: 1,
            child: Semantics(
              label: 'Digit ${i + 1}',
              child: TextField(
                controller: _controllers[i],
                focusNode: _nodes[i],
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                keyboardType: TextInputType.number,
                autofillHints: i == 0 ? const [AutofillHints.oneTimeCode] : null,
                onChanged: (v) => _onChanged(i, v),
                onSubmitted: (_) => widget.onComplete?.call(),
                expands: true,
                maxLines: null,
                style: const TextStyle(fontSize: 22, height: 24 / 22, color: Dak.heading),
                cursorColor: Dak.heading,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: color),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Dak.cta),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          if (i == 3) ...[
            SizedBox(
              width: context.dvw(12, 2, 40),
              child: const Text(
                '-',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.5, color: Dak.heading),
              ),
            ),
            SizedBox(width: gap),
          ],
          box(i),
        ],
      ],
    );
  }
}
