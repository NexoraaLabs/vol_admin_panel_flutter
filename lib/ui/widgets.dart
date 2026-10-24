import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/format.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'asset_icon.dart';
import 'layout.dart';

/// A clickable area with the pointer cursor and no ripple, like a plain <button>/<a> on the web.
class Pressable extends StatelessWidget {
  const Pressable({super.key, required this.onTap, required this.child, this.label});

  final VoidCallback? onTap;
  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: MouseRegion(
        cursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: child),
      ),
    );
  }
}

/// Rebuilds with whether the pointer is over it, for `hover:` styles.
class Hover extends StatefulWidget {
  const Hover({super.key, required this.builder});

  final Widget Function(BuildContext context, bool hovered) builder;

  @override
  State<Hover> createState() => _HoverState();
}

class _HoverState extends State<Hover> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.builder(context, _hovered),
    );
  }
}

/// The panel's pill and rounded buttons. Filled when [fill] is set, outlined when [border] is.
class AdmButton extends StatelessWidget {
  const AdmButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.iconSize = 18,
    this.fill,
    this.border,
    this.color = Dak.heading,
    this.height = 48,
    this.width,
    this.radius = 28,
    this.fontSize = 16,
    this.weight = FontWeight.w500,
    this.letterSpacing = -.32,
    this.padX = 16,
    this.disabledOpacity = .6,
    this.shadow,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onTap;
  final String? icon;
  final double iconSize;
  final Color? fill;
  final Color? border;
  final Color color;
  final double height;
  final double? width;
  final double radius;
  final double fontSize;
  final FontWeight weight;
  final double letterSpacing;
  final double padX;
  final double disabledOpacity;
  final List<BoxShadow>? shadow;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? disabledOpacity : 1,
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: height,
          width: width,
          padding: EdgeInsets.symmetric(horizontal: padX),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
            border: border == null ? null : Border.all(color: border!),
            boxShadow: shadow,
          ),
          child: Row(
            mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[AssetIcon(icon!, width: iconSize, height: iconSize), const SizedBox(width: 8)],
              Text(
                label,
                style: textStyle ?? TextStyle(fontSize: fontSize, fontWeight: weight, letterSpacing: letterSpacing, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A bordered text input that turns purple on focus.
class AdmField extends StatelessWidget {
  const AdmField({
    super.key,
    this.controller,
    this.hint,
    this.height = 40,
    this.radius = 12,
    this.borderColor = Adm.inputBorder,
    this.borderWidth = .5,
    this.fill,
    this.padLeft = 16,
    this.padRight = 16,
    this.prefix,
    this.onChanged,
    this.onSubmitted,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.lines = 1,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.focusNode,
    this.hintColor = Adm.placeholder,
    this.fontSize = 16,
    this.textColor = Dak.heading,
    this.lineHeight,
    this.semanticLabel,
  });

  final TextEditingController? controller;
  final String? hint;
  final double? height;
  final double radius;
  final Color borderColor;
  final double borderWidth;
  final Color? fill;
  final double padLeft;
  final double padRight;
  final Widget? prefix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final int lines;
  final TextAlign textAlign;
  final bool autofocus;
  final FocusNode? focusNode;
  final Color hintColor;
  final double fontSize;
  final Color textColor;
  final double? lineHeight;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder outline(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: c, width: borderWidth),
    );
    final multiline = lines > 1;
    // A multiline field with a height fills it (and scrolls); without one it grows from [lines].
    final expand = multiline && height != null;
    // A single-line field only grows to its text line, so its height comes from vertical padding
    // around a line of known height.
    final line = lineHeight ?? 1.25;
    final padY = multiline ? 17.0 : (height == null ? 10.0 : ((height! - fontSize * line) / 2).clamp(0.0, double.infinity));
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      obscureText: obscure,
      keyboardType: multiline ? TextInputType.multiline : keyboardType,
      autofillHints: autofillHints,
      textAlign: textAlign,
      textAlignVertical: multiline ? TextAlignVertical.top : TextAlignVertical.center,
      minLines: expand ? null : (multiline ? lines : 1),
      maxLines: multiline ? null : 1,
      expands: expand,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(fontSize: fontSize, color: textColor, height: line),
      cursorColor: Dak.heading,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(fontSize: fontSize, color: hintColor, height: line),
        filled: fill != null,
        fillColor: fill,
        prefixIcon: prefix,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: EdgeInsets.fromLTRB(prefix == null ? padLeft : 0, padY, padRight, padY),
        enabledBorder: outline(borderColor),
        focusedBorder: outline(Dak.cta),
        border: outline(borderColor),
      ),
    );
    final sized = height == null ? field : SizedBox(height: height, child: field);
    return semanticLabel == null ? sized : Semantics(label: semanticLabel, textField: true, child: sized);
  }
}

/// "Section - Welcome Header": optional eyebrow above or subtitle below a 32px title, with page
/// actions on the right (wrapping underneath on narrow screens).
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.eyebrow, this.subtitle, this.actions = const []});

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 16, height: 1.5, color: Dak.body);
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eyebrow != null) ...[Text(eyebrow!, style: bodyStyle), const SizedBox(height: 4)],
            Text(
              title,
              style: TextStyle(
                fontSize: context.dvw(24, 2.4, 32),
                fontWeight: FontWeight.w700,
                height: 40 / 32,
                letterSpacing: -.32,
                color: Dak.heading,
              ),
            ),
            if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: bodyStyle)],
          ],
        ),
        if (actions.isNotEmpty) Wrap(spacing: 16, runSpacing: 16, crossAxisAlignment: WrapCrossAlignment.center, children: actions),
      ],
    );
  }
}

/// A stat card's content (lib/admin.ts `Stat`).
class Stat {
  const Stat({required this.label, required this.icon, required this.value, required this.delta, required this.up});

  final String label;
  final String icon;
  final String value;
  final String delta;
  final bool up;

  /// A stat card from an API number and an optional "+8.7%"-style change.
  factory Stat.of(String label, String icon, num value, {String? delta, String? note, bool? up}) => Stat(
    label: label,
    icon: icon,
    value: formatNumber(value),
    delta: note ?? (delta != null ? '$delta vs last month' : ''),
    up: up ?? !(delta?.startsWith('-') ?? false),
  );
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.stat});

  final Stat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: EdgeInsets.symmetric(horizontal: context.cardPadX),
      decoration: BoxDecoration(
        color: Dak.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Dak.cta),
        boxShadow: const [BoxShadow(color: Color(0x409436FB), offset: Offset(0, 4), blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.dvw(13, .73, 14),
                    fontWeight: FontWeight.w500,
                    height: 16 / 14,
                    letterSpacing: .28,
                    color: Dak.body,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AssetIcon(stat.icon, width: 24, height: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            stat.value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500, height: 24 / 28, letterSpacing: .28, color: Dak.heading),
          ),
          const SizedBox(height: 12),
          Text(
            stat.delta,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 16 / 14,
              letterSpacing: .28,
              color: stat.up ? Adm.success : Adm.dangerText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grey pulsing placeholder in a stat card's spot while it loads.
class PulseBox extends StatefulWidget {
  const PulseBox({super.key, this.height = 120});

  final double height;

  @override
  State<PulseBox> createState() => _PulseBoxState();
}

class _PulseBoxState extends State<PulseBox> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: .5).animate(_pulse),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(color: Dak.surface, borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

enum BadgeTone {
  success(Adm.success),
  warning(Adm.warning),
  danger(Adm.danger),
  info(Adm.blue),
  neutral(Dak.muted);

  const BadgeTone(this.color);

  final Color color;
}

BadgeTone accountStatusTone(String label) => switch (label) {
  'Active' => BadgeTone.success,
  'Suspended' => BadgeTone.warning,
  _ => BadgeTone.danger,
};

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final c = tone.color;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 16 / 14, letterSpacing: .28, color: c),
          ),
        ],
      ),
    );
  }
}

class ChipItem {
  const ChipItem(this.value, this.label, {this.href});

  final String value;
  final String label;

  /// When set, picking the chip navigates here so tabs stay URL-addressable.
  final String? href;
}

/// The pill filter/tab row used across the admin screens.
class Chips extends StatelessWidget {
  const Chips({super.key, required this.items, required this.value, this.onChanged, required this.label});

  final List<ChipItem> items;
  final String value;
  final ValueChanged<String>? onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      container: true,
      child: Wrap(
        spacing: 17,
        runSpacing: 17,
        children: [
          for (final item in items)
            _Chip(
              item: item,
              active: item.value == value,
              onTap: () => item.href != null ? context.go(item.href!) : onChanged?.call(item.value),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.item, required this.active, required this.onTap});

  final ChipItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Figma pills are 110px (active) and 150px (idle) at 1920; they scale down with the viewport.
    final minWidth = active ? context.dvw(80, 5.73, 110) : context.dvw(80, 7.8, 150);
    return Hover(
      builder: (context, hovered) => Pressable(
        onTap: onTap,
        child: Container(
          height: 48,
          constraints: BoxConstraints(minWidth: minWidth),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: active ? Dak.cta : null,
            borderRadius: BorderRadius.circular(16),
            border: active ? null : Border.all(color: Adm.chipBorder),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active || hovered ? Colors.white : Colors.white.withValues(alpha: .6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma "Bio Card": dark card with a small uppercase Geist heading over a divider.
class DetailCard extends StatelessWidget {
  const DetailCard({super.key, required this.title, required this.children, this.footer, this.maxWidth = 760});

  final String title;
  final List<Widget> children;
  final Widget? footer;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return MaxWidth(
      maxWidth,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Dak.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Dak.border.withValues(alpha: .4)),
          boxShadow: const [BoxShadow(color: Color(0x332B2B31), offset: Offset(0, 4), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title.toUpperCase(), style: cardTitleStyle()),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.only(top: 18),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Dak.border.withValues(alpha: .4))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 8), children[i]],
                ],
              ),
            ),
            if (footer != null) ...[const SizedBox(height: 16), footer!],
          ],
        ),
      ),
    );
  }
}

/// One label/value line inside a DetailCard. Without a value the label is the line's content.
class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, this.value, this.child});

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null || child != null;
    const valueStyle = TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500, color: Dak.heading);
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Dak.border.withValues(alpha: .4))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: hasValue ? const TextStyle(fontSize: 14, height: 20 / 14, color: Dak.body) : valueStyle,
            ),
          ),
          if (hasValue) ...[
            const SizedBox(width: 16),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: child ?? Text(value!, textAlign: TextAlign.right, style: valueStyle),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The chart/list container ("Widget" in the Next.js panel).
class Panel extends StatelessWidget {
  const Panel({super.key, required this.title, this.subtitle, this.period, required this.child, this.maxWidth});

  final String title;
  final String? subtitle;
  final String? period;
  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Dak.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Dak.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -.2, color: Dak.heading),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(subtitle!, style: const TextStyle(fontSize: 16, letterSpacing: -.2, color: Dak.muted)),
                      ],
                    ],
                  ),
                ),
                if (period != null) ...[
                  const SizedBox(width: 16),
                  Text(period!, style: const TextStyle(fontSize: 14, letterSpacing: -.3, color: Dak.heading)),
                  const SizedBox(width: 4),
                  const AssetIcon('icons/chevron-down.svg', width: 14, height: 14),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
    return maxWidth == null ? panel : MaxWidth(maxWidth!, child: panel);
  }
}

class BackLink extends StatelessWidget {
  const BackLink({super.key, required this.href});

  final String href;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Pressable(
        onTap: () => context.go(href),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.flip(flipX: true, child: const AssetIcon('icons/arrow-right.svg', width: 24, height: 24)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Back',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, color: Dak.heading),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 40×24 switch from Figma's "Toggle Switch": slate track when off, brand purple when on.
class AdmToggle extends StatelessWidget {
  const AdmToggle({super.key, required this.value, required this.onChanged, required this.label});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      child: Pressable(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 24,
          decoration: BoxDecoration(color: value ? Dak.cta : Adm.slate, borderRadius: BorderRadius.circular(12)),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 150),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }
}

/// Body text for loading and error states.
class StateText extends StatelessWidget {
  const StateText(this.text, {super.key, this.error = false, this.center = false, this.padY = 0});

  final String text;
  final bool error;
  final bool center;
  final double padY;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padY),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: TextStyle(fontSize: 16, color: error ? Adm.danger : Dak.body),
      ),
    );
  }
}

/// Vertical stack with a fixed gap, the web's `flex flex-col gap-N`.
class Gap extends StatelessWidget {
  const Gap(this.gap, {super.key, required this.children, this.crossAxisAlignment = CrossAxisAlignment.stretch});

  final double gap;
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
      ],
    );
  }
}
