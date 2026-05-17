import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Custom app icon using the warungpintar SVG.
class AppIcon extends StatelessWidget {
  final double? size;
  final Color? color;

  const AppIcon({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/warungpintar_icon.svg',
      width: size,
      height: size,
    );
  }
}
