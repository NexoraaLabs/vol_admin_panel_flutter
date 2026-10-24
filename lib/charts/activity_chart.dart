import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/admin.dart';
import '../theme/tokens.dart';
import 'chart_theme.dart';

// Bar and tooltip colours from Figma node 742:7. The tooltip shows classrooms in green even though
// the bar itself is #3bcc92, exactly as designed.
const _bars = [
  (key: 'workspaces', label: 'Workspaces', color: Color(0xFF3C6EF7), tip: Color(0xFF3C6EF7)),
  (key: 'canvases', label: 'Canvases', color: Color(0xFF00B5E7), tip: Color(0xFF00B5E7)),
  (key: 'classrooms', label: 'Classrooms', color: Color(0xFF3BCC92), tip: Color(0xFF23C54E)),
  (key: 'catalog', label: 'Catalog', color: Color(0xFFE0BC4B), tip: Color(0xFFE0BC4B)),
];

const _yAxisWidth = 27.0;
const _top = 8.0;
const _xAxisHeight = 30.0;
const _barGap = 4.0;
const _categoryGap = .22;
const _maxBar = 32.0;

/// Grouped weekly bars for "Workspace, canvas, classroom & catalog activity".
class ActivityChart extends StatefulWidget {
  const ActivityChart({super.key, required this.data, this.height = 236});

  final List<ChartPoint> data;
  final double height;

  @override
  State<ActivityChart> createState() => _ActivityChartState();
}

class _ActivityChartState extends State<ActivityChart> {
  int? _hovered;
  Offset _pointer = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    // Figma's axis is 0/300/500/700/1000; keep those proportions but scale to the busiest week.
    final peak = data.fold<num>(0, (m, d) => _bars.fold(m, (m2, b) => math.max(m2, d[b.key])));
    final max = niceMax(peak);

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = Size(box.maxWidth, widget.height);
          final plot = Rect.fromLTRB(_yAxisWidth, _top, size.width, size.height - _xAxisHeight);
          final band = data.isEmpty ? plot.width : plot.width / data.length;
          final hovered = _hovered;

          return MouseRegion(
            onHover: (e) {
              final i = ((e.localPosition.dx - plot.left) / band).floor();
              setState(() {
                _hovered = i >= 0 && i < data.length && e.localPosition.dy <= plot.bottom ? i : null;
                _pointer = e.localPosition;
              });
            },
            onExit: (_) => setState(() => _hovered = null),
            child: Stack(
              children: [
                CustomPaint(
                  size: size,
                  painter: _BarsPainter(data: data, max: max, plot: plot, band: band, hovered: hovered),
                ),
                if (hovered != null)
                  Positioned.fill(
                    child: TooltipLayer(
                      anchor: _pointer,
                      bounds: size,
                      tooltip: ChartTooltip(
                        compact: true,
                        children: [
                          Text(data[hovered].label.replaceAll('WEEK', 'Week'), style: const TextStyle(fontSize: 12, color: Dak.heading)),
                          for (final b in _bars) Text('${b.label}: ${data[hovered][b.key]}', style: TextStyle(fontSize: 10, color: b.tip)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.data, required this.max, required this.plot, required this.band, required this.hovered});

  final List<ChartPoint> data;
  final num max;
  final Rect plot;
  final double band;
  final int? hovered;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = .5;
    for (final f in const [0, .3, .5, .7, 1]) {
      final y = plot.bottom - plot.height * f;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      paintText(canvas, plainNumber((f * max * 10).round() / 10), Offset(plot.left - 6, y), align: TextAlign.right);
    }

    if (hovered != null) {
      canvas.drawRect(
        Rect.fromLTWH(plot.left + band * hovered!, plot.top, band, plot.height),
        Paint()..color = Colors.white.withValues(alpha: .04),
      );
    }

    // Recharts' sizing: the category gap on each side, then equal bars capped at 32px, centred.
    final gap = band * _categoryGap;
    final n = _bars.length;
    final barWidth = math.min(_maxBar, (band - 2 * gap - (n - 1) * _barGap) / n).clamp(1.0, _maxBar);
    final groupWidth = barWidth * n + _barGap * (n - 1);
    for (var i = 0; i < data.length; i++) {
      final left = plot.left + band * i + (band - groupWidth) / 2;
      paintText(canvas, data[i].label, Offset(plot.left + band * (i + .5), plot.bottom + 14 + 5), align: TextAlign.center);
      for (var j = 0; j < n; j++) {
        final value = data[i][_bars[j].key];
        if (value <= 0) continue;
        final h = plot.height * (value / max).clamp(0, 1);
        final rect = Rect.fromLTWH(left + j * (barWidth + _barGap), plot.bottom - h, barWidth, h);
        final r = Radius.circular(math.min(8, math.min(barWidth / 2, h)));
        canvas.drawRRect(RRect.fromRectAndCorners(rect, topLeft: r, topRight: r), Paint()..color = _bars[j].color);
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.data != data || old.hovered != hovered || old.plot != plot;
}
