import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/tokens.dart';
import '../settings/view_models/settings_view_model.dart';
import 'glass_tab_bar.dart';
import 'sidebar.dart';

/// Top-level frame around the two sections.
///
/// * expanded: full dark sidebar (collapsible to an icon rail)
/// * medium:   icon rail
/// * compact:  bottom navigation bar, hidden while writing an entry; floats
///             as a glass capsule in portrait
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell, required this.location});

  final StatefulNavigationShell navigationShell;
  final String location;

  void _onSelect(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the active section again returns to its root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = WindowSize.of(context);

    if (!size.isCompact) {
      final collapsed = !size.isExpanded || context.select((SettingsViewModel s) => s.sidebarCollapsed);
      return Scaffold(
        body: Row(
          children: [
            Sidebar(
              currentIndex: navigationShell.currentIndex,
              onSelect: _onSelect,
              collapsed: collapsed,
              canCollapse: size.isExpanded,
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    final hideNav = Routes.isJournalEditor(location);
    if (MediaQuery.orientationOf(context) == Orientation.portrait) {
      return _FloatingNavShell(
        navigationShell: navigationShell,
        // Keep the bar out of the way while the keyboard is up.
        showNav: !hideNav && MediaQuery.viewInsetsOf(context).bottom == 0,
        onSelect: _onSelect,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: hideNav
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _onSelect,
                destinations: [
                  for (final d in Sidebar.destinations)
                    NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selected), label: d.label),
                ],
              ),
            ),
    );
  }
}

/// Compact portrait: an iOS-style glass tab bar floats above the content,
/// which scrolls (blurred) underneath it.
///
/// The bar's footprint is added to the page's padding *and* view padding, so
/// SafeAreas, scroll views and nested FABs all clear it.
class _FloatingNavShell extends StatelessWidget {
  const _FloatingNavShell({required this.navigationShell, required this.showNav, required this.onSelect});

  final StatefulNavigationShell navigationShell;
  final bool showNav;
  final ValueChanged<int> onSelect;

  static const double _margin = Space.md;

  @override
  Widget build(BuildContext context) {
    if (!showNav) return Scaffold(body: navigationShell);

    final media = MediaQuery.of(context);
    final systemInset = media.padding.bottom;
    final footprint = GlassTabBar.height + _margin + systemInset;

    return Scaffold(
      body: Stack(
        children: [
          MediaQuery(
            data: media.copyWith(
              padding: media.padding.copyWith(bottom: footprint),
              viewPadding: media.viewPadding.copyWith(bottom: footprint),
            ),
            child: navigationShell,
          ),
          Positioned(
            left: Space.lg,
            right: Space.lg,
            bottom: _margin + systemInset,
            child: GlassTabBar(selectedIndex: navigationShell.currentIndex, onSelect: onSelect),
          ),
        ],
      ),
    );
  }
}
