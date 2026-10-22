import 'package:flutter/widgets.dart';

/// Spacing scale (4pt grid). Use these instead of ad-hoc numbers so rhythm
/// stays consistent across screens.
abstract final class Space {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Corner radii. Small and crisp, like a productivity tool.
abstract final class Radii {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double pill = 999;

  static final smAll = BorderRadius.circular(sm);
  static final mdAll = BorderRadius.circular(md);
  static final lgAll = BorderRadius.circular(lg);
}

/// Layout breakpoints, based on the window width.
///
/// compact  (< 640):        bottom navigation, single pane
/// medium   (640 – 1099):   icon rail, list + editor when space allows
/// expanded (≥ 1100):       full sidebar, list + editor
enum WindowSize {
  compact,
  medium,
  expanded;

  static WindowSize of(BuildContext context) => fromWidth(MediaQuery.sizeOf(context).width);

  static WindowSize fromWidth(double width) => width < 640
      ? compact
      : width < 1100
      ? medium
      : expanded;

  bool get isCompact => this == compact;
  bool get isExpanded => this == expanded;

  /// Horizontal page gutter for this size.
  double get gutter => switch (this) {
    compact => Space.lg,
    medium => Space.xl,
    expanded => Space.xxl,
  };
}

/// Shared motion durations.
abstract final class Motion {
  static const fast = Duration(milliseconds: 120);
  static const medium = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 320);
}
