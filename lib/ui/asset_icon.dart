import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/format.dart';
import '../theme/tokens.dart';

/// An image from assets/, svg or raster. [color] tints every painted pixel.
class AssetIcon extends StatelessWidget {
  const AssetIcon(this.path, {super.key, this.width, this.height, this.color, this.fit = BoxFit.contain});

  final String path;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final asset = 'assets/$path';
    if (path.endsWith('.svg')) {
      return SvgPicture.asset(
        asset,
        width: width,
        height: height,
        fit: fit,
        colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
      );
    }
    return Image.asset(asset, width: width, height: height, fit: fit, color: color);
  }
}

/// Round avatar: the user's photo, or their initials on a purple disc (UsersTable's UserAvatar).
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.src, required this.name, this.size = 40, this.fallbackAsset});

  final String? src;
  final String name;
  final double size;

  /// Shown instead of initials when there is no name either (the top nav before sign-in loads).
  final String? fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (src != null && src!.isNotEmpty) {
      content = Image.network(src!, fit: BoxFit.cover, width: size, height: size, errorBuilder: (_, _, _) => _letters());
    } else if (name.isEmpty && fallbackAsset != null) {
      content = AssetIcon(fallbackAsset!, width: size, height: size, fit: BoxFit.cover);
    } else {
      content = _letters();
    }
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Dak.cta, shape: BoxShape.circle),
      child: content,
    );
  }

  Widget _letters() => Text(
    initials(name),
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: size * .36),
  );
}
