import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';

/// The app mark: a green rounded square with a notebook glyph.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.of(context).success, borderRadius: BorderRadius.circular(Radii.md)),
      child: Icon(Icons.auto_stories_rounded, size: size * 0.6, color: Colors.white),
    );
  }
}
