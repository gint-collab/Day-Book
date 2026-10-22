import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../core/widgets/app_logo.dart';
import '../journal/view_models/journal_view_model.dart';
import '../settings/view_models/settings_view_model.dart';
import '../todos/view_models/todo_view_model.dart';

/// Evernote-style dark navigation sidebar.
class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.collapsed,
    required this.canCollapse,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final bool collapsed;
  final bool canCollapse;

  static const expandedWidth = 248.0;
  static const collapsedWidth = 68.0;

  static const destinations = [
    (icon: Icons.auto_stories_outlined, selected: Icons.auto_stories, label: 'Journal'),
    (icon: Icons.check_circle_outline, selected: Icons.check_circle, label: 'To-dos'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final journal = context.watch<JournalViewModel>();
    final todos = context.watch<TodoViewModel>();
    final settings = context.watch<SettingsViewModel>();
    final platform = MediaQuery.platformBrightnessOf(context);
    final isDark = settings.isDark(platform);
    final tags = journal.allTags.take(8).toList();

    final counts = [journal.entries.length, todos.activeCount];

    return AnimatedContainer(
      duration: Motion.medium,
      curve: Curves.easeOutCubic,
      width: collapsed ? collapsedWidth : expandedWidth,
      color: colors.sidebar,
      child: SafeArea(
        right: false,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            maxWidth: collapsed ? collapsedWidth : expandedWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Brand(collapsed: collapsed),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: collapsed ? Space.md : Space.lg, vertical: Space.sm),
                  child: _NewButton(collapsed: collapsed),
                ),
                const SizedBox(height: Space.sm),
                for (final (i, d) in destinations.indexed)
                  _SidebarItem(
                    icon: currentIndex == i ? d.selected : d.icon,
                    label: d.label,
                    trailing: counts[i] > 0 ? '${counts[i]}' : null,
                    selected: currentIndex == i,
                    collapsed: collapsed,
                    onTap: () => onSelect(i),
                  ),
                if (!collapsed && tags.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.xl, Space.xl, Space.lg, Space.sm),
                    child: Text(
                      'TAGS',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: colors.sidebarMuted, fontWeight: FontWeight.w600, letterSpacing: 0.8),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final t in tags)
                          _SidebarItem(
                            icon: Icons.tag,
                            label: t.tag,
                            trailing: '${t.count}',
                            dense: true,
                            selected: currentIndex == 0 && journal.tagFilter == t.tag,
                            collapsed: false,
                            onTap: () {
                              journal.setTagFilter(t.tag);
                              context.go(Routes.journal);
                            },
                          ),
                      ],
                    ),
                  ),
                ] else
                  const Spacer(),
                Divider(color: colors.sidebarDivider, height: 1),
                const SizedBox(height: Space.sm),
                _SidebarItem(
                  icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  label: isDark ? 'Light theme' : 'Dark theme',
                  collapsed: collapsed,
                  onTap: () => settings.toggleTheme(platform),
                ),
                if (canCollapse)
                  _SidebarItem(
                    icon: collapsed ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left,
                    label: 'Collapse sidebar',
                    tooltip: collapsed ? 'Expand sidebar' : null,
                    collapsed: collapsed,
                    onTap: settings.toggleSidebar,
                  ),
                const SizedBox(height: Space.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      height: 64,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: collapsed ? 20 : Space.xl - 4),
        child: Row(
          children: [
            const AppLogo(),
            if (!collapsed) ...[
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(
                  'Daybook',
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.sidebarText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewButton extends StatelessWidget {
  const _NewButton({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textStyle = Theme.of(context).textTheme.labelLarge
        ?.copyWith(fontWeight: FontWeight.w600, color: Colors.white);

    return PopupMenuButton<String>(
      tooltip: 'Create new',
      offset: const Offset(0, 48),
      onSelected: (v) => context.go(v == 'entry' ? Routes.journalNew : Routes.todosCompose),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'entry',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_note),
            title: Text('Journal entry'),
          ),
        ),
        PopupMenuItem(
          value: 'task',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.add_task),
            title: Text('Task'),
          ),
        ),
      ],
      child: AnimatedContainer(
        duration: Motion.medium,
        height: 44,
        decoration: BoxDecoration(color: colors.success, borderRadius: BorderRadius.circular(Radii.pill)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 22),
            if (!collapsed) ...[const SizedBox(width: Space.sm), Text('New', style: textStyle)],
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.collapsed,
    required this.onTap,
    this.trailing,
    this.selected = false,
    this.dense = false,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final bool collapsed;
  final VoidCallback onTap;
  final String? trailing;
  final bool selected;
  final bool dense;
  final String? tooltip;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final fg = widget.selected ? colors.sidebarText : colors.sidebarText.withValues(alpha: 0.82);
    final bg = widget.selected
        ? colors.sidebarSelected
        : _hovered
        ? colors.sidebarHover
        : Colors.transparent;

    final item = Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.collapsed ? Space.md : Space.sm + 2, vertical: 1),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: Motion.fast,
            height: widget.dense ? 34 : 40,
            padding: EdgeInsets.symmetric(horizontal: widget.collapsed ? 0 : Space.md),
            decoration: BoxDecoration(color: bg, borderRadius: Radii.mdAll),
            child: Row(
              mainAxisAlignment: widget.collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  widget.icon,
                  size: widget.dense ? 16 : 20,
                  color: widget.selected ? colors.success : colors.sidebarMuted,
                ),
                if (!widget.collapsed) ...[
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (widget.dense ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)?.copyWith(
                        color: fg,
                        fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.trailing != null)
                    Text(widget.trailing!, style: theme.textTheme.labelSmall?.copyWith(color: colors.sidebarMuted)),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    final semantics = Semantics(button: true, selected: widget.selected, label: widget.label, child: item);
    return widget.collapsed
        ? Tooltip(message: widget.tooltip ?? widget.label, preferBelow: false, child: semantics)
        : semantics;
  }
}
