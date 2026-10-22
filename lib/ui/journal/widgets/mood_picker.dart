import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../data/models/mood.dart';

/// Five mood pills. Shows emoji + label when there's room, emoji only on
/// narrow widths. Tapping the selected mood again clears it.
class MoodPicker extends StatelessWidget {
  const MoodPicker({super.key, required this.selected, required this.onSelect});

  final Mood? selected;
  final ValueChanged<Mood> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showLabels = constraints.maxWidth / Mood.values.length >= 88;
        return Row(
          children: [
            for (final (i, mood) in Mood.values.indexed) ...[
              if (i > 0) const SizedBox(width: Space.sm - 2),
              Expanded(
                child: _MoodOption(
                  mood: mood,
                  showLabel: showLabels,
                  isSelected: selected == mood,
                  isDimmed: selected != null && selected != mood,
                  onTap: () => onSelect(mood),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MoodOption extends StatelessWidget {
  const _MoodOption({
    required this.mood,
    required this.showLabel,
    required this.isSelected,
    required this.isDimmed,
    required this.onTap,
  });

  final Mood mood;
  final bool showLabel;
  final bool isSelected;
  final bool isDimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final option = Semantics(
      button: true,
      selected: isSelected,
      label: 'Mood: ${mood.label}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.mdAll,
          child: AnimatedContainer(
            duration: Motion.medium,
            curve: Curves.easeOut,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? mood.color.withValues(alpha: 0.14) : Colors.transparent,
              borderRadius: Radii.mdAll,
              border: Border.all(
                color: isSelected ? mood.color.withValues(alpha: 0.8) : scheme.outlineVariant,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: AnimatedOpacity(
              opacity: isDimmed ? 0.5 : 1,
              duration: Motion.medium,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.15 : 1,
                    duration: Motion.medium,
                    child: Text(mood.emoji, style: const TextStyle(fontSize: 18)),
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: Space.xs + 2),
                    Flexible(
                      child: Text(
                        mood.label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isSelected ? mood.color : scheme.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return showLabel ? option : Tooltip(message: mood.label, child: option);
  }
}
