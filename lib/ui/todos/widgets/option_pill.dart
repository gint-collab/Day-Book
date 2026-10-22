import 'package:flutter/material.dart';

/// Small rounded label with an icon — tinted with [color] when set,
/// neutral outline otherwise. Used for due dates and priorities.
class OptionPill extends StatelessWidget {
  const OptionPill({super.key, required this.icon, required this.label, this.color, this.dense = false});

  final IconData icon;
  final String label;
  final Color? color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = color ?? scheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.symmetric(horizontal: dense ? 7 : 10, vertical: dense ? 2 : 5),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color?.withValues(alpha: 0.35) ?? scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 13 : 15, color: fg),
          SizedBox(width: dense ? 4 : 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (dense ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
