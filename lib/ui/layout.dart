import 'package:flutter/material.dart';

// Tailwind breakpoints used by apps/admin.
const sm = 640.0;
const lg = 1024.0;
const xl = 1280.0;
const xxl = 1536.0;

/// Figma's canvas width. Desktop viewports narrower than this are zoomed to keep its proportions.
const figmaWidth = 1920.0;

extension LayoutContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isSm => screenWidth >= sm;
  bool get isLg => screenWidth >= lg;
  bool get isXl => screenWidth >= xl;
  bool get is2xl => screenWidth >= xxl;

  /// CSS `clamp(min, <vh>vh, max)`.
  double dvh(double min, double vh, double max) => (screenHeight * vh / 100).clamp(min, max);

  /// CSS `clamp(min, <vw>vw, max)`.
  double dvw(double min, double vw, double max) => (screenWidth * vw / 100).clamp(min, max);

  /// `--adm-sidebar-w`: Figma's 400px sidebar scaled with the viewport, capped at 400px.
  double get sidebarWidth => dvw(260, 20.8333, 400);

  /// The panel's horizontal card padding, `clamp(16px, 3.61vw - 29.3px, 40px)`.
  double get cardPadX => (screenWidth * .0361 - 29.3).clamp(16, 40);
}

/// The Next.js panel sets `zoom: width / 1920` on desktop viewports narrower than 1920px. This does
/// the same: the app lays out on a 1920px-wide canvas and is scaled down to fit the window.
class FigmaZoom extends StatelessWidget {
  const FigmaZoom({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    if (size.width < lg || size.width >= figmaWidth) return child;

    final zoom = size.width / figmaWidth;
    final logical = Size(figmaWidth, size.height / zoom);
    return FittedBox(
      fit: BoxFit.fill,
      alignment: Alignment.topLeft,
      child: SizedBox.fromSize(
        size: logical,
        child: MediaQuery(
          data: media.copyWith(size: logical, padding: media.padding / zoom, viewInsets: media.viewInsets / zoom),
          child: child,
        ),
      ),
    );
  }
}

/// Lays [children] out in rows of [columns] equal-width cells, like a CSS grid with `grid-cols-N`.
class GridRows extends StatelessWidget {
  const GridRows({super.key, required this.columns, required this.children, this.gapX = 19, this.gapY = 16});

  final int columns;
  final List<Widget> children;
  final double gapX;
  final double gapY;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final cells = children.sublist(i, (i + columns).clamp(0, children.length));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) SizedBox(width: gapX),
              Expanded(child: j < cells.length ? cells[j] : const SizedBox.shrink()),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[if (i > 0) SizedBox(height: gapY), rows[i]],
      ],
    );
  }
}

/// Two widgets side by side in an `800fr 590fr` split on xl screens, stacked otherwise.
class SplitRow extends StatelessWidget {
  const SplitRow({super.key, required this.left, required this.right, this.gap = 24});

  final Widget left;
  final Widget right;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (!context.isXl) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          left,
          SizedBox(height: gap),
          right,
        ],
      );
    }
    // Top-aligned rather than equal heights: the charts use LayoutBuilder, which can't report the
    // intrinsic height a stretched row would need.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 800, child: left),
        SizedBox(width: gap),
        Expanded(flex: 590, child: right),
      ],
    );
  }
}

/// One column of a CSS grid template: `minmax(min, fr)`, or a fixed width when [fr] is 0.
typedef Track = ({double min, double fr});

/// Column widths for a `grid-template-columns` of [tracks] in [total] px. Tracks whose share of
/// the free space would fall under their minimum are frozen at it and the rest re-shared.
List<double> trackWidths(double total, List<Track> tracks) {
  final widths = [for (final t in tracks) t.min];
  final frozen = [for (final t in tracks) t.fr == 0];
  while (true) {
    final free =
        total -
        [
          for (var i = 0; i < tracks.length; i++)
            if (frozen[i]) widths[i],
        ].fold(0.0, (a, b) => a + b);
    final frs = [
      for (var i = 0; i < tracks.length; i++)
        if (!frozen[i]) tracks[i].fr,
    ].fold(0.0, (a, b) => a + b);
    if (frs == 0) return widths;
    var changed = false;
    for (var i = 0; i < tracks.length; i++) {
      if (frozen[i]) continue;
      final share = free * tracks[i].fr / frs;
      if (share < tracks[i].min) {
        widths[i] = tracks[i].min;
        frozen[i] = true;
        changed = true;
      } else {
        widths[i] = share;
      }
    }
    if (!changed) return widths;
  }
}

/// A grid row: [cells] laid out at [widths] with [gap] between them.
class TrackRow extends StatelessWidget {
  const TrackRow({super.key, required this.widths, required this.cells, this.gap = 0});

  final List<double> widths;
  final List<Widget> cells;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < cells.length; i++) ...[if (i > 0 && gap > 0) SizedBox(width: gap), SizedBox(width: widths[i], child: cells[i])],
      ],
    );
  }
}

/// A table that keeps a minimum width and scrolls sideways when the space is narrower.
class ScrollTable extends StatelessWidget {
  const ScrollTable({super.key, required this.minWidth, required this.builder});

  final double minWidth;
  final Widget Function(double width) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth < minWidth ? minWidth : box.maxWidth;
        final table = SizedBox(width: width, child: builder(width));
        return box.maxWidth < minWidth ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: table) : table;
      },
    );
  }
}

/// `max-w-[N]` on a block element: full width up to [maxWidth], left-aligned.
class MaxWidth extends StatelessWidget {
  const MaxWidth(this.maxWidth, {super.key, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
