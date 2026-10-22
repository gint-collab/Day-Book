import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/models/journal_entry.dart';
import 'tag_pill.dart';

/// A note-list row: title, two-line snippet, then date · mood · tags.
/// Highlights on hover and shows a green edge when [selected].
class JournalEntryCard extends StatefulWidget {
  const JournalEntryCard({super.key, required this.entry, required this.onTap, this.selected = false});

  final JournalEntry entry;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<JournalEntryCard> createState() => _JournalEntryCardState();
}

class _JournalEntryCardState extends State<JournalEntryCard> {
  static const _maxTags = 3;

  bool _hovered = false;

  static String _date(DateTime d) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(d, now)) return DateFormat.jm().format(d);
    if (d.year == now.year) return DateFormat('MMM d').format(d);
    return DateFormat('MMM d, y').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final muted = scheme.onSurfaceVariant;
    final selected = widget.selected;

    final tags = entry.allTags;
    final snippet = [entry.body, if (entry.body.isEmpty) entry.gratitude].where((s) => s.isNotEmpty).join();

    return Semantics(
      selected: selected,
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: Motion.fast,
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.md + 2, Space.lg, Space.md + 2),
            decoration: BoxDecoration(
              color: selected
                  ? colors.selection
                  : _hovered
                  ? scheme.onSurface.withValues(alpha: 0.04)
                  : scheme.surfaceContainerLowest,
              borderRadius: Radii.mdAll,
              border: Border.all(color: selected ? scheme.primary.withValues(alpha: 0.55) : scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title.isEmpty ? 'Untitled' : entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(color: entry.title.isEmpty ? muted : null),
                      ),
                    ),
                    if (entry.mood != null) ...[
                      const SizedBox(width: Space.sm),
                      Tooltip(
                        message: entry.mood!.label,
                        child: Text(entry.mood!.emoji, style: const TextStyle(fontSize: 16, height: 1.2)),
                      ),
                    ],
                  ],
                ),
                if (snippet.isNotEmpty) ...[
                  const SizedBox(height: Space.xs),
                  Text(
                    snippet,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.5),
                  ),
                ],
                const SizedBox(height: Space.sm + 2),
                Row(
                  children: [
                    Text(
                      _date(entry.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: selected ? scheme.primary : muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (entry.gratitude.isNotEmpty) ...[
                      const SizedBox(width: Space.sm),
                      Icon(Icons.favorite, size: 11, color: colors.danger.withValues(alpha: 0.7)),
                    ],
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: Space.sm),
                  Wrap(
                    spacing: Space.xs + 1,
                    runSpacing: Space.xs + 1,
                    children: [
                      for (final t in tags.take(_maxTags)) TagPill(t, dense: true),
                      if (tags.length > _maxTags)
                        Tooltip(
                          message: tags.skip(_maxTags).map((t) => '#$t').join('  '),
                          child: Text(
                            '+${tags.length - _maxTags}',
                            style: theme.textTheme.labelSmall?.copyWith(color: muted, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
