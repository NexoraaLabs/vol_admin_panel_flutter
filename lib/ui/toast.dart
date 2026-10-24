import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';
import 'asset_icon.dart';
import 'layout.dart';
import 'widgets.dart';

// The tinted fills are Figma's 15% tones flattened onto the black page so the toast stays opaque.
enum ToastTone {
  warning(Adm.warning, Color(0xFF2A2306)),
  danger(Adm.danger, Color(0xFF2A0D0E)),
  info(Adm.blue, Color(0xFF0D1A2F)),
  success(Adm.success, Color(0xFF0A2312));

  const ToastTone(this.color, this.fill);

  final Color color;
  final Color fill;
}

class ToastData {
  const ToastData(this.id, this.title, this.message, this.tone);

  final int id;
  final String title;
  final String message;
  final ToastTone tone;
}

/// `ref.read(toastProvider.notifier).show('Ban user completed', tone: ToastTone.danger)`.
/// One toast at a time; a new one replaces the last.
final toastProvider = NotifierProvider<ToastNotifier, ToastData?>(ToastNotifier.new);

class ToastNotifier extends Notifier<ToastData?> {
  var _nextId = 0;
  Timer? _timer;

  @override
  ToastData? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void show(String title, {String message = 'Action recorded in the audit log.', ToastTone tone = ToastTone.info}) {
    _timer?.cancel();
    state = ToastData(++_nextId, title, message, tone);
    _timer = Timer(const Duration(seconds: 5), close);
  }

  void close() {
    _timer?.cancel();
    state = null;
  }
}

/// Figma node 789:4595: bottom-right confirmation with a round close button over its corner.
class ToastHost extends ConsumerWidget {
  const ToastHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider);
    return Stack(
      children: [
        child,
        if (toast != null)
          Positioned(
            key: ValueKey(toast.id),
            right: context.isSm ? 50 : 16,
            bottom: 24,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.screenWidth - 32),
              child: _Toast(toast: toast, onClose: ref.read(toastProvider.notifier).close),
            ),
          ),
      ],
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.toast, required this.onClose});

  final ToastData toast;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tone = toast.tone;
    return Semantics(
      liveRegion: true,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: tone.fill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tone.color),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AssetIcon('icons/check-circle.svg', width: 24, height: 24, color: tone.color),
                  const SizedBox(width: 11),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          toast.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 32 / 18, color: Dak.heading),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          toast.message,
                          style: const TextStyle(fontSize: 14, height: 20 / 14, color: Dak.body),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: -4,
              top: -10,
              child: Pressable(
                onTap: onClose,
                label: 'Dismiss',
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Dak.muted, borderRadius: BorderRadius.circular(30)),
                  child: const AssetIcon('icons/close-x.svg', width: 14, height: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
