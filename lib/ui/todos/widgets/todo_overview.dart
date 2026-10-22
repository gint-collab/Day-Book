import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

import '../view_models/todo_view_model.dart';

/// Progress ring plus three tappable "smart list" tiles that double as
/// due-date filters (Overdue / Today / Upcoming).
class TodoOverview extends StatelessWidget {
  const TodoOverview({super.key, required this.vm});

  final TodoViewModel vm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: Radii.lgAll,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: vm.progress),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: scheme.surfaceContainerHigh,
                      ),
                    ),
                    Center(
                      child: Text(
                        '${vm.progressPercent}%',
                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${vm.doneCount} of ${vm.totalCount} done', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      vm.progressSummary,
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SmartTile(
                icon: Icons.error_outline,
                label: 'Overdue',
                count: vm.overdueCount,
                color: vm.overdueCount > 0 ? scheme.error : scheme.onSurfaceVariant,
                selected: vm.due == DueFilter.overdue,
                onTap: () => vm.setDue(DueFilter.overdue),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SmartTile(
                icon: Icons.today_outlined,
                label: 'Today',
                count: vm.dueTodayCount + vm.overdueCount,
                color: scheme.primary,
                selected: vm.due == DueFilter.today,
                onTap: () => vm.setDue(DueFilter.today),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SmartTile(
                icon: Icons.upcoming_outlined,
                label: 'Upcoming',
                count: vm.upcomingCount,
                color: scheme.tertiary,
                selected: vm.due == DueFilter.upcoming,
                onTap: () => vm.setDue(DueFilter.upcoming),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SmartTile extends StatelessWidget {
  const _SmartTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = Radii.lgAll;

    return Semantics(
      selected: selected,
      button: true,
      label: '$label, $count tasks',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : scheme.surfaceContainerLowest,
          borderRadius: radius,
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.6) : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: color),
                      const Spacer(),
                      if (selected) Icon(Icons.filter_alt, size: 14, color: color),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('$count', style: theme.textTheme.titleLarge?.copyWith(height: 1)),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
