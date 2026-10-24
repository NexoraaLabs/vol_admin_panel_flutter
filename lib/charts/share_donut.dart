import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'chart_theme.dart';

class DonutSlice {
  const DonutSlice(this.name, this.value, this.color);

  final String name;
  final num value;
  final Color color;
}

// Recharts angles run counter-clockwise from 3 o'clock; the donut starts at 62° and goes clockwise.
const _startDeg = -62.0;
const _paddingDeg = 2.0;

/// Donut from Figma node 790:5518 ("Share of platform accounts by type") with the legend spread
/// along the bottom of the widget.
class ShareDonut extends StatefulWidget {
  const ShareDonut({super.key, required this.data});

  final List<DonutSlice> data;

  @override
  State<ShareDonut> createState() => _ShareDonutState();
}

class _ShareDonutState extends State<ShareDonut> {
  int? _hovered;
  Offset _pointer = Offset.zero;

  List<(double start, double sweep)> _arcs() {
    final shown = widget.data.where((d) => d.value > 0).length;
    final total = widget.data.fold<num>(0, (s, d) => s + d.value);
    final available = 360 - _paddingDeg * shown;
    var angle = _startDeg;
    return [
      for (final d in widget.data)
        () {
          final sweep = total == 0 ? 0.0 : available * d.value / total;
          final arc = (angle, sweep);
          if (d.value > 0) angle += sweep + _paddingDeg;
          return arc;
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final arcs = _arcs();
    final hovered = _hovered;
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: SizedBox(
            height: 290,
            child: LayoutBuilder(
              builder: (context, box) {
                final size = Size(box.maxWidth, 290);
                final center = size.center(Offset.zero);
                final maxR = math.min(size.width, size.height) / 2;
                final outer = maxR * .8;
                final inner = maxR * .5;

                int? hit(Offset p) {
                  final v = p - center;
                  if (v.distance < inner || v.distance > outer) return null;
                  var deg = math.atan2(v.dy, v.dx) * 180 / math.pi;
                  for (var i = 0; i < arcs.length; i++) {
                    final (start, sweep) = arcs[i];
                    final rel = (deg - start) % 360;
                    if (sweep > 0 && rel <= sweep) return i;
                  }
                  return null;
                }

                return MouseRegion(
                  onHover: (e) => setState(() {
                    _hovered = hit(e.localPosition);
                    _pointer = e.localPosition;
                  }),
                  onExit: (_) => setState(() => _hovered = null),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: size,
                        painter: _DonutPainter(slices: widget.data, arcs: arcs, center: center, inner: inner, outer: outer),
                      ),
                      if (hovered != null)
                        Positioned.fill(
                          child: TooltipLayer(
                            anchor: _pointer,
                            bounds: size,
                            tooltip: ChartTooltip(
                              compact: true,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '${widget.data[hovered].name}: ${widget.data[hovered].value}',
                                    style: TextStyle(fontSize: 10, color: widget.data[hovered].color),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 32),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 647),
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final d in widget.data)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: d.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        d.name,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: -.3, color: Dak.body),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices, required this.arcs, required this.center, required this.inner, required this.outer});

  final List<DonutSlice> slices;
  final List<(double, double)> arcs;
  final Offset center;
  final double inner;
  final double outer;

  @override
  void paint(Canvas canvas, Size size) {
    const rad = math.pi / 180;
    for (var i = 0; i < slices.length; i++) {
      final (start, sweep) = arcs[i];
      if (sweep <= 0) continue;
      final path = Path()
        ..arcTo(Rect.fromCircle(center: center, radius: outer), start * rad, sweep * rad, true)
        ..arcTo(Rect.fromCircle(center: center, radius: inner), (start + sweep) * rad, -sweep * rad, false)
        ..close();
      canvas.drawPath(path, Paint()..color = slices[i].color);
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.slices != slices || old.center != center;
}
