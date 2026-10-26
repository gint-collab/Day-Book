import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/models/priority.dart';
import '../../../data/models/todo.dart';
import '../../../data/models/todo_list_style.dart';
import '../../core/widgets/about_button.dart';
import '../../core/widgets/chip_scroller.dart';
import '../../core/widgets/content_frame.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/theme_toggle_button.dart';
import '../../settings/view_models/settings_view_model.dart';
import '../view_models/todo_view_model.dart';
import '../widgets/simple_todo.dart';
import '../widgets/todo_editor_sheet.dart';
import '../widgets/todo_input.dart';
import '../widgets/todo_overview.dart';
import '../widgets/todo_tile.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key, this.compose = false});

  /// Focus the quick-add field on arrival (from the sidebar's "New → Task").
  final bool compose;

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  late final TextEditingController _search;
  final _composerFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: context.read<TodoViewModel>().query);
    if (widget.compose) _focusComposer();
  }

  @override
  void didUpdateWidget(TodoScreen old) {
    super.didUpdateWidget(old);
    if (widget.compose && !old.compose) _focusComposer();
  }

  void _focusComposer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _composerFocus.requestFocus();
      // Drop the query flag so revisiting the tab doesn't refocus.
      context.go(Routes.todos);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  void _clearFilters(TodoViewModel vm) {
    _search.clear();
    vm.clearFilters();
  }

  Future<void> _delete(TodoViewModel vm, Todo todo) async {
    final removed = await vm.delete(todo.id);
    if (removed == null || !mounted) return;
    showToast(context, 'Deleted “${removed.title}”', undo: () => vm.restore([removed]));
  }

  Future<void> _clearCompleted(TodoViewModel vm) async {
    final removed = await vm.clearCompleted();
    if (removed.isEmpty || !mounted) return;
    showToast(
      context,
      'Cleared ${removed.length} completed ${removed.length == 1 ? 'task' : 'tasks'}',
      undo: () => vm.restore(removed),
    );
  }

  Future<void> _edit(TodoViewModel vm, Todo todo) async {
    final result = await showTodoEditor(context, todo);
    switch (result) {
      case TodoEdited(:final todo):
        await vm.update(todo);
      case TodoDeleteRequested():
        await _delete(vm, todo);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TodoViewModel>();
    final simple = context.select((SettingsViewModel s) => s.todoListStyle) == TodoListStyle.simple;
    final size = WindowSize.of(context);
    final gutter = size.gutter;

    return Scaffold(
      // The bottom inset is applied inside the scroll view so content can
      // scroll beneath a floating navigation bar.
      body: SafeArea(
        bottom: false,
        child: ContentFrame(
          maxWidth: 800,
          child: CustomScrollView(
            key: const PageStorageKey('todo-list'),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, size.isCompact ? Space.lg : Space.xl, gutter - Space.xs, 0),
                sliver: SliverToBoxAdapter(
                  child: PageHeader(
                    title: 'To-dos',
                    subtitle: vm.isEmpty
                        ? 'Capture what needs doing'
                        : '${vm.activeCount} active · ${vm.doneCount} done',
                    actions: [
                      const _ListStyleButton(),
                      if (!simple && !vm.isEmpty) _SortMenu(vm: vm),
                      if (vm.hasCompleted)
                        PopupMenuButton<String>(
                          tooltip: 'More',
                          icon: const Icon(Icons.more_horiz),
                          onSelected: (_) => _clearCompleted(vm),
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'clear', child: Text('Clear ${vm.doneCount} completed')),
                          ],
                        ),
                      if (size.isCompact) ...const [ThemeToggleButton(), AboutButton()],
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, Space.lg, gutter, 0),
                sliver: SliverToBoxAdapter(
                  child: simple
                      ? SimpleTodoInput(onSubmitted: vm.add, focusNode: _composerFocus)
                      : TodoInput(onSubmitted: vm.add, focusNode: _composerFocus),
                ),
              ),
              ..._buildBody(vm, gutter, simple: simple),
              SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody(TodoViewModel vm, double gutter, {required bool simple}) {
    if (vm.isLoading && vm.isEmpty) {
      return const [SliverFillRemaining(child: Center(child: CircularProgressIndicator()))];
    }
    if (vm.error != null) {
      return [SliverFillRemaining(child: Center(child: Text(vm.error!)))];
    }
    if (vm.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.task_alt,
            title: 'Nothing on your plate',
            message: 'Add a task above. Give it a due date or a priority to keep things in order.',
          ),
        ),
      ];
    }
    if (simple) return _checklist(vm, gutter);

    final active = vm.visibleActive;
    final done = vm.visibleDone;
    final showDoneSection = vm.status != TodoStatus.active && done.isNotEmpty;
    final doneExpanded = vm.status == TodoStatus.done || vm.completedExpanded;
    EdgeInsets pad(double top, [double bottom = 0]) => EdgeInsets.fromLTRB(gutter, top, gutter, bottom);

    return [
      SliverPadding(
        padding: pad(Space.lg),
        sliver: SliverToBoxAdapter(child: TodoOverview(vm: vm)),
      ),
      SliverPadding(
        padding: pad(Space.xl),
        sliver: SliverToBoxAdapter(
          child: _FilterBar(controller: _search, vm: vm, onClear: () => _clearFilters(vm)),
        ),
      ),
      if (!vm.hasVisible)
        SliverFillRemaining(hasScrollBody: false, child: _noResults(vm))
      else ...[
        if (vm.status != TodoStatus.done) ...[
          SliverPadding(
            padding: pad(Space.xl, Space.sm),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(label: 'To do', count: active.length),
            ),
          ),
          if (active.isEmpty)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              sliver: const SliverToBoxAdapter(child: _AllDoneBanner()),
            )
          else
            _tiles(vm, active, gutter),
        ],
        if (showDoneSection) ...[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, Space.xl, gutter - Space.sm, Space.xs),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                label: 'Completed',
                count: done.length,
                expanded: vm.status == TodoStatus.done ? null : doneExpanded,
                onToggle: vm.status == TodoStatus.done ? null : vm.toggleCompletedExpanded,
                trailing: TextButton(onPressed: () => _clearCompleted(vm), child: const Text('Clear')),
              ),
            ),
          ),
          if (doneExpanded) _tiles(vm, done, gutter, gap: Space.xs),
        ],
      ],
      const SliverToBoxAdapter(child: SizedBox(height: Space.xxxl)),
    ];
  }

  Widget _tiles(TodoViewModel vm, List<Todo> todos, double gutter, {double gap = Space.sm - 2}) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      sliver: SliverList.separated(
        itemCount: todos.length,
        separatorBuilder: (_, _) => SizedBox(height: gap),
        itemBuilder: (context, i) {
          final todo = todos[i];
          return TodoTile(
            key: ValueKey(todo.id),
            todo: todo,
            onToggle: () => vm.toggle(todo.id),
            onEdit: () => _edit(vm, todo),
            onDelete: () => _delete(vm, todo),
          );
        },
      ),
    );
  }

  List<Widget> _checklist(TodoViewModel vm, double gutter) {
    final todos = vm.checklist;
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter - Space.sm, Space.md, gutter - Space.sm, Space.xxxl),
        sliver: SliverList.builder(
          itemCount: todos.length,
          itemBuilder: (context, i) {
            final todo = todos[i];
            return SimpleTodoTile(
              key: ValueKey(todo.id),
              todo: todo,
              onToggle: () => vm.toggle(todo.id),
              onDelete: () => _delete(vm, todo),
            );
          },
        ),
      ),
    ];
  }

  Widget _noResults(TodoViewModel vm) {
    if (vm.isFiltering) {
      return EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'No matching tasks',
        message: 'Nothing fits these filters right now.',
        action: TextButton(onPressed: () => _clearFilters(vm), child: const Text('Clear filters')),
      );
    }
    return switch (vm.status) {
      TodoStatus.done => const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'Nothing completed yet',
        message: 'Tick off a task and it will land here.',
      ),
      _ => const EmptyState(
        icon: Icons.celebration_outlined,
        title: 'All caught up',
        message: 'No active tasks. Enjoy the quiet.',
      ),
    };
  }
}

/// Switches between the detailed planner and the simple checklist. The
/// choice is saved with the other settings.
class _ListStyleButton extends StatelessWidget {
  const _ListStyleButton();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    final simple = settings.todoListStyle == TodoListStyle.simple;
    return IconButton(
      tooltip: simple ? 'Switch to detailed list' : 'Switch to simple list',
      onPressed: () => settings.setTodoListStyle(simple ? TodoListStyle.detailed : TodoListStyle.simple),
      icon: Icon(simple ? Icons.view_agenda_outlined : Icons.checklist, size: 20),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.vm});

  final TodoViewModel vm;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TodoSort>(
      tooltip: 'Sort',
      initialValue: vm.sort,
      onSelected: vm.setSort,
      icon: const Icon(Icons.swap_vert),
      itemBuilder: (_) => [
        const PopupMenuItem(enabled: false, height: 32, child: Eyebrow('Sort tasks by')),
        for (final s in TodoSort.values)
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Expanded(child: Text(s.label)),
                if (s == vm.sort) Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller, required this.vm, required this.onClear});

  final TextEditingController controller;
  final TodoViewModel vm;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = WindowSize.of(context).isCompact;

    final status = SegmentedButton<TodoStatus>(
      showSelectedIcon: false,
      segments: [
        for (final s in TodoStatus.values)
          ButtonSegment(
            value: s,
            label: Text(switch (s) {
              TodoStatus.all => 'All',
              TodoStatus.active => 'Active ${vm.activeCount}',
              TodoStatus.done => 'Done ${vm.doneCount}',
            }),
          ),
      ],
      selected: {vm.status},
      onSelectionChanged: (s) => vm.setStatus(s.first),
    );

    final search = TextField(
      controller: controller,
      onChanged: vm.setQuery,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search tasks',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: vm.query.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  controller.clear();
                  vm.setQuery('');
                },
              )
            : null,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Stacked on phones; side by side when there's room.
        if (compact) ...[
          search,
          const SizedBox(height: Space.sm + 2),
          Align(alignment: Alignment.centerLeft, child: status),
        ] else
          Row(
            children: [
              status,
              const SizedBox(width: Space.md),
              Expanded(child: search),
            ],
          ),
        const SizedBox(height: Space.sm + 2),
        ChipScroller(
          children: [
            for (final p in [Priority.high, Priority.medium, Priority.low])
              FilterChip(
                avatar: Icon(Icons.flag, size: 16, color: p.color),
                label: Text(p.label),
                selected: vm.priority == p,
                selectedColor: p.color.withValues(alpha: 0.16),
                side: BorderSide(color: vm.priority == p ? p.color.withValues(alpha: 0.7) : scheme.outlineVariant),
                onSelected: (_) => vm.setPriority(p),
              ),
            FilterChip(
              avatar: const Icon(Icons.event_busy_outlined, size: 16),
              label: const Text('No date'),
              selected: vm.due == DueFilter.noDate,
              onSelected: (_) => vm.setDue(DueFilter.noDate),
            ),
            if (vm.isFiltering)
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Clear filters'),
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count, this.expanded, this.onToggle, this.trailing});

  final String label;
  final int count;

  /// Null hides the chevron (section not collapsible).
  final bool? expanded;
  final VoidCallback? onToggle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Eyebrow(label, color: theme.colorScheme.onSurface),
        const SizedBox(width: Space.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Space.sm - 1, vertical: 1),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(color: muted, fontWeight: FontWeight.w700),
          ),
        ),
        if (expanded != null) ...[
          const SizedBox(width: Space.xs),
          AnimatedRotation(
            turns: expanded! ? 0 : -0.25,
            duration: Motion.medium,
            child: Icon(Icons.expand_more, size: 20, color: muted),
          ),
        ],
      ],
    );

    return Row(
      children: [
        if (onToggle != null)
          InkWell(
            borderRadius: Radii.mdAll,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: title,
            ),
          )
        else
          title,
        const SizedBox(width: Space.md),
        const Expanded(child: Divider()),
        ?trailing,
      ],
    );
  }
}

class _AllDoneBanner extends StatelessWidget {
  const _AllDoneBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md + 2),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: Radii.lgAll),
      child: Row(
        children: [
          Icon(Icons.celebration_outlined, size: 20, color: scheme.onPrimaryContainer),
          const SizedBox(width: Space.md),
          Expanded(
            child: Text(
              'All caught up. Nothing left on this list.',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
