import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Figma's growth charts space their y-axis ticks evenly even though the values aren't
/// (0, 10k, 20k, 50k, 100k). Values are mapped onto evenly spaced "tick positions" by linear
/// interpolation between neighbouring ticks, and the axis labels the positions with the real values.
double tickPosition(List<num> ticks, num v) {
  if (v <= ticks.first) return 0;
  for (var i = 1; i < ticks.length; i++) {
    if (v <= ticks[i]) return i - 1 + (v - ticks[i - 1]) / (ticks[i] - ticks[i - 1]);
  }
  return ticks.length - 1.0;
}

String formatK(num v) {
  if (v < 1000) return plainNumber(v);
  return '${plainNumber(double.parse((v / 1000).toStringAsFixed(1)))}k';
}

/// 300.0 -> "300", 2.5 -> "2.5".
String plainNumber(num v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

/// The next 1/2/5×10ⁿ at or above [peak], at least 10.
num niceMax(num peak) {
  num max = 10;
  while (max < peak) {
    final lead = '$max'[0];
    max = lead == '1' ? max * 2 : (lead == '2' ? max ~/ 2 * 5 : max * 2);
  }
  return max;
}

/// [0, M/10, M/5, M/2, M] where M = [niceMax] of the peak.
List<num> growthTicks(num peak) {
  final max = niceMax(peak);
  return [0, max / 10, max / 5, max / 2, max];
}

const axisStyle = TextStyle(color: Color(0xFFC8CBD0), fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: -.3);

const gridColor = Color(0xFF777A82);

void paintText(Canvas canvas, String text, Offset at, {TextAlign align = TextAlign.left, TextStyle style = axisStyle}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final dx = switch (align) {
    TextAlign.center => at.dx - painter.width / 2,
    TextAlign.right => at.dx - painter.width,
    _ => at.dx,
  };
  painter.paint(canvas, Offset(dx, at.dy - painter.height / 2));
}

/// The dark rounded tooltip box.
class ChartTooltip extends StatelessWidget {
  const ChartTooltip({super.key, required this.children, this.compact = false});

  final List<Widget> children;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final gap = compact ? 8.0 : 16.0;
    return IgnorePointer(
      child: Container(
        width: compact ? null : 149,
        padding: EdgeInsets.all(compact ? 8 : 16),
        decoration: BoxDecoration(
          color: Adm.tooltip,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Adm.tooltipBorder),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(letterSpacing: -.3, fontSize: compact ? null : 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
            ],
          ),
        ),
      ),
    );
  }
}

/// Places [tooltip] beside the pointer at [anchor], flipping left when it would leave [bounds].
class TooltipLayer extends StatelessWidget {
  const TooltipLayer({super.key, required this.anchor, required this.bounds, required this.tooltip});

  final Offset anchor;
  final Size bounds;
  final Widget tooltip;

  @override
  Widget build(BuildContext context) {
    return CustomSingleChildLayout(delegate: _TooltipDelegate(anchor), child: tooltip);
  }
}

class _TooltipDelegate extends SingleChildLayoutDelegate {
  _TooltipDelegate(this.anchor);

  final Offset anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) {
    const offset = 10.0;
    var x = anchor.dx + offset;
    if (x + child.width > size.width) x = anchor.dx - offset - child.width;
    var y = anchor.dy + offset;
    if (y + child.height > size.height) y = size.height - child.height;
    return Offset(x.clamp(0, (size.width - child.width).clamp(0, double.infinity)), y.clamp(0, double.infinity));
  }

  @override
  bool shouldRelayout(_TooltipDelegate old) => old.anchor != anchor;
}
