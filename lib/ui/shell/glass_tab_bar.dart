import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import 'sidebar.dart';

/// iOS-style floating tab bar: a frosted-glass capsule with a sliding glass
/// highlight behind the selected tab.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const double height = 64;
  static const double _inset = Space.xs;
  static const double _tabWidth = 104;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final destinations = Sidebar.destinations;
    final shape = BorderRadius.circular(Radii.pill);

    // Sized to its tabs and centred, rather than stretched edge to edge.
    final bar = DecoratedBox(
      // The shadow sits outside the clip so the glass keeps its soft lift.
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.12 : 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: shape,
              // A faint top-to-bottom sheen reads as light on curved glass.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.surface.withValues(alpha: isLight ? 0.72 : 0.55),
                  scheme.surface.withValues(alpha: isLight ? 0.55 : 0.4),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: isLight ? 0.6 : 0.12)),
            ),
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.all(_inset),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / destinations.length;
                    return Stack(
                      children: [
                        AnimatedPositioned(
                          duration: Motion.slow,
                          curve: Curves.easeOutBack,
                          left: itemWidth * selectedIndex,
                          top: 0,
                          bottom: 0,
                          width: itemWidth,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: shape,
                              color: isLight
                                  ? Colors.black.withValues(alpha: 0.06)
                                  : Colors.white.withValues(alpha: 0.12),
                              border: Border.all(color: Colors.white.withValues(alpha: isLight ? 0.5 : 0.08)),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < destinations.length; i++)
                              Expanded(
                                child: _GlassTab(
                                  icon: i == selectedIndex ? destinations[i].selected : destinations[i].icon,
                                  label: destinations[i].label,
                                  selected: i == selectedIndex,
                                  onTap: () => onSelect(i),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _tabWidth * destinations.length + _inset * 2),
        child: bar,
      ),
    );
  }
}

class _GlassTab extends StatelessWidget {
  const _GlassTab({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: Motion.medium,
              curve: Curves.easeOut,
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: Space.xxs),
            AnimatedDefaultTextStyle(
              duration: Motion.medium,
              style: theme.textTheme.labelSmall!.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
