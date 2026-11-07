import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/color_theme.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';
import 'widgets.dart';

/// Top bar button that switches between the default and the colour-blind friendly themes.
class ColorThemeMenu extends ConsumerWidget {
  const ColorThemeMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(colorThemeProvider);

    return MenuAnchor(
      alignmentOffset: const Offset(-260, 8),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Dak.surface),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Dak.border),
          ),
        ),
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Text(
            'Colour theme',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: .6, color: Dak.muted),
          ),
        ),
        for (final theme in ColorTheme.values)
          MenuItemButton(
            onPressed: () => ref.read(colorThemeProvider.notifier).select(theme),
            style: ButtonStyle(
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              backgroundColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.focused) ? Adm.rowHover : null,
              ),
            ),
            child: SizedBox(
              width: 260,
              child: Row(
                children: [
                  _Swatches(theme.palette),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          theme.label,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Dak.heading),
                        ),
                        Text(theme.hint, style: TextStyle(fontSize: 12, color: Dak.muted)),
                      ],
                    ),
                  ),
                  if (theme == current) Icon(Icons.check, size: 18, color: Dak.cta),
                ],
              ),
            ),
          ),
      ],
      builder: (context, menu, _) => Tooltip(
        message: 'Colour theme',
        child: Pressable(
          label: 'Colour theme',
          onTap: () => menu.isOpen ? menu.close() : menu.open(),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.palette_outlined, size: 20, color: Dak.heading),
          ),
        ),
      ),
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches(this.palette);

  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in [palette.cta, palette.success, palette.warning, palette.danger])
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
          ),
      ],
    );
  }
}
