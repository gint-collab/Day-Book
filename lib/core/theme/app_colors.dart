import 'package:flutter/material.dart';

/// App-specific colours that don't map onto [ColorScheme] roles:
/// the navigation sidebar, the middle "list" pane and semantic accents.
///
/// Read with `AppColors.of(context)`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.sidebar,
    required this.sidebarText,
    required this.sidebarMuted,
    required this.sidebarHover,
    required this.sidebarSelected,
    required this.sidebarDivider,
    required this.listPane,
    required this.selection,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color sidebar;
  final Color sidebarText;
  final Color sidebarMuted;
  final Color sidebarHover;
  final Color sidebarSelected;
  final Color sidebarDivider;

  /// Background of list columns (note list, task list) — a step off the
  /// editor's surface so panes read as separate.
  final Color listPane;

  /// Background of the selected row in a list.
  final Color selection;

  final Color success;
  final Color warning;
  final Color danger;

  static AppColors of(BuildContext context) => Theme.of(context).extension<AppColors>()!;

  static const light = AppColors(
    sidebar: Color(0xFF1A1A1A),
    sidebarText: Color(0xFFEDEDED),
    sidebarMuted: Color(0xFF9A9A9A),
    sidebarHover: Color(0xFF2A2A2A),
    sidebarSelected: Color(0xFF333333),
    sidebarDivider: Color(0xFF2E2E2E),
    listPane: Color(0xFFF7F7F5),
    selection: Color(0xFFE9F6EC),
    success: Color(0xFF00A82D),
    warning: Color(0xFFD9822B),
    danger: Color(0xFFD64545),
  );

  static const dark = AppColors(
    sidebar: Color(0xFF111111),
    sidebarText: Color(0xFFE6E6E6),
    sidebarMuted: Color(0xFF8C8C8C),
    sidebarHover: Color(0xFF1F1F1F),
    sidebarSelected: Color(0xFF2A2A2A),
    sidebarDivider: Color(0xFF242424),
    listPane: Color(0xFF1A1A1A),
    selection: Color(0xFF1E3326),
    success: Color(0xFF2DBE60),
    warning: Color(0xFFE59A4C),
    danger: Color(0xFFE5645F),
  );

  @override
  AppColors copyWith({
    Color? sidebar,
    Color? sidebarText,
    Color? sidebarMuted,
    Color? sidebarHover,
    Color? sidebarSelected,
    Color? sidebarDivider,
    Color? listPane,
    Color? selection,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return AppColors(
      sidebar: sidebar ?? this.sidebar,
      sidebarText: sidebarText ?? this.sidebarText,
      sidebarMuted: sidebarMuted ?? this.sidebarMuted,
      sidebarHover: sidebarHover ?? this.sidebarHover,
      sidebarSelected: sidebarSelected ?? this.sidebarSelected,
      sidebarDivider: sidebarDivider ?? this.sidebarDivider,
      listPane: listPane ?? this.listPane,
      selection: selection ?? this.selection,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      sidebar: l(sidebar, other.sidebar),
      sidebarText: l(sidebarText, other.sidebarText),
      sidebarMuted: l(sidebarMuted, other.sidebarMuted),
      sidebarHover: l(sidebarHover, other.sidebarHover),
      sidebarSelected: l(sidebarSelected, other.sidebarSelected),
      sidebarDivider: l(sidebarDivider, other.sidebarDivider),
      listPane: l(listPane, other.listPane),
      selection: l(selection, other.selection),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
    );
  }
}
