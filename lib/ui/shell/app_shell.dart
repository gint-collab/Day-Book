import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/tokens.dart';
import '../settings/settings_view_model.dart';
import 'sidebar.dart';

/// Top-level frame around the two sections.
///
/// * expanded: full dark sidebar (collapsible to an icon rail)
/// * medium:   icon rail
/// * compact:  bottom navigation bar, hidden while writing an entry
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
