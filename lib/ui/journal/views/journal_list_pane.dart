import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/models/mood.dart';
import '../../core/widgets/about_button.dart';
import '../../core/widgets/chip_scroller.dart';
import '../../core/widgets/content_frame.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/theme_toggle_button.dart';
import '../view_models/journal_view_model.dart';
import '../widgets/journal_entry_card.dart';
import '../widgets/journal_overview.dart';

/// The entry list: header, search & filters, insights and grouped entries.
///
/// [inSplit] = shown as a column next to the editor (tinted background,
/// tighter padding) rather than as a full screen.
class JournalListPane extends StatefulWidget {
  const JournalListPane({super.key, required this.selectedId, this.creating = false, required this.inSplit});

  final String? selectedId;
  final bool creating;
  final bool inSplit;

  @override
  State<JournalListPane> createState() => _JournalListPaneState();
}

class _JournalListPaneState extends State<JournalListPane> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: context.read<JournalViewModel>().query);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters(JournalViewModel vm) {
    _search.clear();
    vm.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JournalViewModel>();
    final size = WindowSize.of(context);
    final inSplit = widget.inSplit;
    final gutter = inSplit ? Space.lg : size.gutter;
    final showFab = !inSplit && !vm.isEmpty;

    final slivers = <Widget>[
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, size.isCompact ? Space.lg : Space.xl, gutter - Space.xs, 0),
        sliver: SliverToBoxAdapter(
          child: PageHeader(
            title: 'Journal',
            subtitle: vm.isEmpty
                ? 'Your private space to write'
                : '${vm.entries.length} ${vm.entries.length == 1 ? 'entry' : 'entries'}',
            actions: [
              if (size.isCompact) ...const [ThemeToggleButton(), AboutButton()],
              if (inSplit && !vm.isEmpty)
                IconButton.filledTonal(
                  tooltip: 'New entry',
                  onPressed: () => context.go(Routes.journalNew),
                  icon: const Icon(Icons.add, size: 20),
                ),
            ],
          ),
        ),
      ),
      ..._body(context, vm, gutter),
      // The bottom inset lives here rather than in SafeArea so content can
      // scroll beneath a floating navigation bar.
      SliverToBoxAdapter(child: SizedBox(height: (showFab ? 96 : Space.xl) + MediaQuery.paddingOf(context).bottom)),
    ];

    return Scaffold(
      backgroundColor: inSplit ? AppColors.of(context).listPane : Theme.of(context).colorScheme.surface,
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => context.go(Routes.journalNew),
              icon: Icon(vm.hasDraft ? Icons.edit_note : Icons.add),
              label: Text(vm.hasDraft ? 'Continue draft' : 'New entry'),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: ContentFrame(
          maxWidth: inSplit ? double.infinity : 760,
          child: CustomScrollView(key: const PageStorageKey('journal-list'), slivers: slivers),
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, JournalViewModel vm, double gutter) {
    if (vm.isLoading && vm.isEmpty) {
      return const [SliverFillRemaining(child: Center(child: CircularProgressIndicator()))];
    }
    if (vm.error != null) {
      return [SliverFillRemaining(child: Center(child: Text(vm.error!)))];
    }
    if (vm.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.auto_stories_outlined,
            title: vm.hasDraft ? 'You have a draft waiting' : 'Start your journal',
            message: 'Log how you feel, what happened and what you’re grateful for. A few lines a day adds up.',
            action: FilledButton.icon(
              onPressed: () => context.go(Routes.journalNew),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(vm.hasDraft ? 'Continue draft' : 'Write your first entry'),
            ),
          ),
        ),
      ];
    }

    final groups = vm.groupedEntries;
    EdgeInsets pad(double top) => EdgeInsets.fromLTRB(gutter, top, gutter, 0);

    return [
      SliverPadding(
        padding: pad(Space.lg),
        sliver: SliverToBoxAdapter(
          child: _SearchAndFilter(controller: _search, vm: vm, onClear: () => _clearFilters(vm)),
        ),
      ),
      if (!vm.isFiltering) ...[
        if (!vm.wroteToday)
          SliverPadding(
            padding: pad(Space.lg),
            sliver: SliverToBoxAdapter(
              child: _TodayPrompt(hasDraft: vm.hasDraft, active: widget.creating),
            ),
          ),
        SliverPadding(
          padding: pad(Space.md),
          sliver: SliverToBoxAdapter(
            child: JournalOverview(
              entryCount: vm.entries.length,
              streak: vm.streak,
              totalWords: vm.totalWords,
              weekMoods: vm.weekMoods,
              weekAverage: vm.weekAverageMood,
            ),
          ),
        ),
      ],
      if (groups.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.search_off,
            title: 'No matching entries',
            message: 'Try another word, or clear the filters.',
            action: TextButton(onPressed: () => _clearFilters(vm), child: const Text('Clear filters')),
          ),
        )
      else
        for (final group in groups) ...[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter + Space.xs, Space.xl, gutter, Space.sm),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Eyebrow(group.label),
                  const SizedBox(width: Space.sm),
                  Eyebrow('${group.entries.length}', color: Theme.of(context).colorScheme.outline),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            sliver: SliverList.separated(
              itemCount: group.entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.sm - 2),
              itemBuilder: (context, i) {
                final entry = group.entries[i];
                return JournalEntryCard(
                  key: ValueKey(entry.id),
                  entry: entry,
                  selected: entry.id == widget.selectedId,
                  onTap: () => context.go(Routes.journalEdit(entry.id)),
                );
              },
            ),
          ),
        ],
    ];
  }
}

class _TodayPrompt extends StatelessWidget {
  const _TodayPrompt({required this.hasDraft, required this.active});

  final bool hasDraft;

  /// The new-entry editor is already open next to the list.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: Radii.lgAll,
      child: InkWell(
        borderRadius: Radii.lgAll,
        onTap: active ? null : () => context.go(Routes.journalNew),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md + 2),
          child: Row(
            children: [
              Icon(hasDraft ? Icons.edit_note : Icons.wb_twilight_rounded, size: 20, color: scheme.onPrimaryContainer),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(
                  hasDraft ? 'Pick up your unfinished draft' : 'You haven’t written today. How are you feeling?',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!active) Icon(Icons.arrow_forward_rounded, size: 18, color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  const _SearchAndFilter({required this.controller, required this.vm, required this.onClear});

  final TextEditingController controller;
  final JournalViewModel vm;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: vm.setQuery,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search entries',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: vm.isFiltering
                ? IconButton(tooltip: 'Clear filters', icon: const Icon(Icons.close, size: 18), onPressed: onClear)
                : null,
          ),
        ),
        const SizedBox(height: Space.sm + 2),
        ChipScroller(
          children: [
            if (vm.tagFilter != null)
              InputChip(
                avatar: Icon(Icons.tag, size: 16, color: scheme.onPrimaryContainer),
                label: Text(vm.tagFilter!),
                selected: true,
                onDeleted: () => vm.setTagFilter(vm.tagFilter),
                onPressed: () => vm.setTagFilter(vm.tagFilter),
                deleteIcon: const Icon(Icons.close, size: 14),
              ),
            for (final mood in Mood.values)
              FilterChip(
                tooltip: mood.label,
                avatar: Text(mood.emoji, style: const TextStyle(fontSize: 14)),
                label: Text(mood.label),
                selected: vm.moodFilter == mood,
                onSelected: (_) => vm.setMoodFilter(mood),
                selectedColor: mood.color.withValues(alpha: 0.16),
                labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: vm.moodFilter == mood ? mood.color : null,
                  fontWeight: vm.moodFilter == mood ? FontWeight.w600 : null,
                ),
                side: BorderSide(
                  color: vm.moodFilter == mood ? mood.color.withValues(alpha: 0.7) : scheme.outlineVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
