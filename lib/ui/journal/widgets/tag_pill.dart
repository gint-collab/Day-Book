import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// A `#tag` pill in the accent colour. Shows a remove ✕ when [onRemove] is set.
class TagPill extends StatelessWidget {
  const TagPill(this.tag, {super.key, this.onRemove, this.dense = false});

  final String tag;
  final VoidCallback? onRemove;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = scheme.onPrimaryContainer;

    return Container(
      padding: EdgeInsets.fromLTRB(dense ? 7 : 9, dense ? 1 : 3, onRemove == null ? (dense ? 7 : 9) : 3, dense ? 1 : 3),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(Radii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              '#$tag',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (dense ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRemove != null)
            Semantics(
              button: true,
              label: 'Remove tag $tag',
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(Icons.close, size: 13, color: fg),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
