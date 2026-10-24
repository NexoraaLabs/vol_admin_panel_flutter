import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/admin.dart';
import '../theme/tokens.dart';
import 'chart_theme.dart';

enum GrowthStroke {
  /// Solid line from the first point up to the hovered one (User Growth).
  progress,

  /// Dashed outline along the whole area (Business Growth).
  dashed,
}

class GrowthSeries {
  const GrowthSeries({required this.key, required this.label, required this.color, this.stroke, this.accent});

  final String key;
  final String label;
  final Color color;
  final GrowthStroke? stroke;

  /// Dot and tooltip colour when it differs from the area (Business Growth: purple area, green dot).
  final Color? accent;
}

const _yAxisWidth = 56.0;
const _top = 8.0;
const _xAxisHeight = 30.0;

/// The area chart behind Figma's "User Growth" and "Business Growth" widgets (705:3181): gradient
/// fills fading to transparent, a light vertical cursor and a dark tooltip, shown at first on the
/// point Figma highlights ([defaultIndex]) and following the pointer afterwards.
class GrowthChart extends StatefulWidget {
  const GrowthChart({super.key, required this.data, required this.series, required this.defaultIndex, this.height = 236});

  final List<ChartPoint> data;
  final List<GrowthSeries> series;
  final int defaultIndex;
  final double height;

  @override
  State<GrowthChart> createState() => _GrowthChartState();
}

class _GrowthChartState extends State<GrowthChart> {
  late int _active = widget.defaultIndex;
  var _showTip = true;
  Offset? _pointer;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final peak = data.fold<num>(0, (m, d) => widget.series.fold(m, (m2, s) => d[s.key] > m2 ? d[s.key] : m2));
    final ticks = growthTicks(peak);
    final active = data.isEmpty ? 0 : _active.clamp(0, data.length - 1);

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = Size(box.maxWidth, widget.height);
          final plot = Rect.fromLTRB(_yAxisWidth, _top, size.width, size.height - _xAxisHeight);
          double xAt(int i) => data.length < 2 ? plot.left : plot.left + plot.width * i / (data.length - 1);
          double yAt(num v) => plot.bottom - plot.height * tickPosition(ticks, v) / (ticks.length - 1);

          int nearest(Offset p) {
            if (data.length < 2) return 0;
            return ((p.dx - plot.left) / plot.width * (data.length - 1)).round().clamp(0, data.length - 1);
          }

          final point = data.isEmpty ? null : data[active];
          final anchor = _pointer ?? Offset(xAt(active), plot.top + plot.height / 3);

          return MouseRegion(
            onHover: (e) => setState(() {
              _active = nearest(e.localPosition);
              _pointer = e.localPosition;
              _showTip = true;
            }),
            onExit: (_) => setState(() => _showTip = false),
            child: Stack(
              children: [
                CustomPaint(
                  size: size,
                  painter: _GrowthPainter(
                    data: data,
                    series: widget.series,
                    ticks: ticks,
                    plot: plot,
                    active: active,
                    showCursor: _showTip,
                    xAt: xAt,
                    yAt: yAt,
                  ),
                ),
                // The trailing unlabeled point only extends the area to the plot edge, as in Figma.
                if (_showTip && point != null && point.label.isNotEmpty)
                  Positioned.fill(
                    child: TooltipLayer(
                      anchor: anchor,
                      bounds: size,
                      tooltip: ChartTooltip(
                        children: [
                          Text(point.label, style: const TextStyle(color: Dak.heading)),
                          for (final s in widget.series)
                            Text('${s.label}: ${plainNumber(point[s.key])}', style: TextStyle(color: s.accent ?? s.color)),
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

class _GrowthPainter extends CustomPainter {
  _GrowthPainter({
    required this.data,
    required this.series,
    required this.ticks,
    required this.plot,
    required this.active,
    required this.showCursor,
    required this.xAt,
    required this.yAt,
  });

  final List<ChartPoint> data;
  final List<GrowthSeries> series;
  final List<num> ticks;
  final Rect plot;
  final int active;
  final bool showCursor;
  final double Function(int) xAt;
  final double Function(num) yAt;

  @override
  void paint(Canvas canvas, Size size) {
    // Vertical grid at every point, horizontal grid at every tick.
    final vGrid = Paint()..color = const Color(0xFF282828);
    for (var i = 0; i < data.length; i++) {
      canvas.drawLine(Offset(xAt(i), plot.top), Offset(xAt(i), plot.bottom), vGrid);
    }
    final hGrid = Paint()
      ..color = gridColor
      ..strokeWidth = .5;
    for (var i = 0; i < ticks.length; i++) {
      final y = plot.bottom - plot.height * i / (ticks.length - 1);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), hGrid);
      // Left-aligned y labels, flush with the widget's padding as in Figma.
      paintText(canvas, formatK(ticks[i]), Offset(1, y));
    }
    for (var i = 0; i < data.length; i++) {
      paintText(canvas, data[i].label, Offset(xAt(i), plot.bottom + 16 + 5), align: TextAlign.center);
    }
    if (data.isEmpty) return;

    for (final s in series) {
      final line = Path()..moveTo(xAt(0), yAt(data[0][s.key]));
      for (var i = 1; i < data.length; i++) {
        line.lineTo(xAt(i), yAt(data[i][s.key]));
      }
      final area = Path.from(line)
        ..lineTo(xAt(data.length - 1), plot.bottom)
        ..lineTo(xAt(0), plot.bottom)
        ..close();
      final bounds = area.getBounds();
      canvas.drawPath(
        area,
        Paint()
          ..shader = ui.Gradient.linear(bounds.topCenter, bounds.bottomCenter, [
            s.color.withValues(alpha: .4),
            s.color.withValues(alpha: 0),
          ]),
      );
      if (s.stroke == GrowthStroke.dashed) {
        _dashed(
          canvas,
          line,
          Paint()
            ..color = s.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
      if (s.stroke == GrowthStroke.progress) {
        final progress = Path()..moveTo(xAt(0), yAt(data[0][s.key]));
        for (var i = 1; i <= active; i++) {
          progress.lineTo(xAt(i), yAt(data[i][s.key]));
        }
        canvas.drawPath(
          progress,
          Paint()
            ..color = s.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    if (!showCursor) return;
    final x = xAt(active);
    canvas.drawLine(
      Offset(x, plot.top),
      Offset(x, plot.bottom),
      Paint()
        ..color = const Color(0xFFD9D9D9)
        ..strokeWidth = 2,
    );
    for (final s in series) {
      canvas.drawCircle(Offset(x, yAt(data[active][s.key])), 6, Paint()..color = s.accent ?? s.color);
    }
  }

  void _dashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 4) {
        canvas.drawPath(metric.extractPath(d, d + 2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GrowthPainter old) =>
      old.data != data || old.active != active || old.showCursor != showCursor || old.plot != plot || old.series != series;
}
