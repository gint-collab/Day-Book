import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../settings/settings_view_model.dart';

/// Sun / moon button that flips between light and dark themes.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    final platform = MediaQuery.platformBrightnessOf(context);
    final isDark = settings.isDark(platform);
    return IconButton(
      tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
      color: color,
      onPressed: () => settings.toggleTheme(platform),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, a) => RotationTransition(
          turns: Tween(begin: 0.75, end: 1.0).animate(a),
          child: FadeTransition(opacity: a, child: child),
        ),
        child: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, key: ValueKey(isDark), size: 20),
      ),
    );
  }
}
