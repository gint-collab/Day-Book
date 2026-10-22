import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../data/models/mood.dart';

/// Compact insight card: streak · entries · words, plus a 7-day mood strip.
/// Sized to fit a ~300px list column as well as a full-width phone screen.
class JournalOverview extends StatelessWidget {
  const JournalOverview({
    super.key,
    required this.entryCount,
    required this.streak,
    required this.totalWords,
    required this.weekMoods,
    required this.weekAverage,
  });

  final int entryCount;
  final int streak;
  final int totalWords;
  final List<({DateTime day, Mood? mood})> weekMoods;
  final Mood? weekAverage;

  static String _compact(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = DateTime.now();

    Widget divider() => Container(width: 1, height: 28, color: scheme.outlineVariant);

    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: Radii.lgAll,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.local_fire_department_rounded,
                  value: '$streak',
                  label: 'day streak',
                  color: const Color(0xFFE8833A),
                ),
              ),
              divider(),
              Expanded(
                child: _Stat(
                  icon: Icons.auto_stories_outlined,
                  value: '$entryCount',
                  label: entryCount == 1 ? 'entry' : 'entries',
                  color: scheme.primary,
                ),
              ),
              divider(),
              Expanded(
                child: _Stat(
                  icon: Icons.notes_rounded,
                  value: _compact(totalWords),
                  label: 'words',
                  color: scheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Text('This week', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Flexible(
                child: Text(
                  weekAverage == null
                      ? 'No moods yet'
                      : 'Mostly ${weekAverage!.label.toLowerCase()} ${weekAverage!.emoji}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: weekAverage?.color ?? scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm + 2),
          Row(
            children: [
              for (final d in weekMoods)
                Expanded(
                  child: Tooltip(
                    message: [DateFormat('EEE, MMM d').format(d.day), ?d.mood?.label].join(' · '),
                    child: Column(
                      children: [
                        _MoodDot(mood: d.mood, isToday: DateUtils.isSameDay(d.day, today)),
                        const SizedBox(height: Space.xs + 1),
                        Text(
                          DateFormat('E').format(d.day).substring(0, 1),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: DateUtils.isSameDay(d.day, today) ? scheme.primary : scheme.onSurfaceVariant,
                            fontWeight: DateUtils.isSameDay(d.day, today) ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label, required this.color});

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: Space.xs),
            Text(value, style: theme.textTheme.titleMedium?.copyWith(height: 1.1)),
          ],
        ),
        const SizedBox(height: Space.xxs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _MoodDot extends StatelessWidget {
  const _MoodDot({required this.mood, required this.isToday});

  final Mood? mood;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: mood == null ? scheme.surfaceContainer : mood!.color.withValues(alpha: 0.18),
        border: isToday ? Border.all(color: scheme.primary, width: 1.5) : null,
      ),
      child: mood == null ? null : Text(mood!.emoji, style: const TextStyle(fontSize: 14)),
    );
  }
}
