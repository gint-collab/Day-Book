import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

import '../../../data/models/priority.dart';
import '../../../data/models/todo.dart';
import 'due_dates.dart';
import 'option_pill.dart';

/// A task row. Active tasks sit on a raised card with a priority-coloured
/// check ring; completed tasks sink into the background — flat, muted,
/// struck through, with a filled check and a completion time.
class TodoTile extends StatefulWidget {
  const TodoTile({super.key, required this.todo, required this.onToggle, required this.onEdit, required this.onDelete});

  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<TodoTile> createState() => _TodoTileState();
}

class _TodoTileState extends State<TodoTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = todo.isDone;
    final muted = scheme.onSurfaceVariant;
    final radius = Radii.lgAll;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: done
            ? scheme.surfaceContainerLow.withValues(alpha: 0.7)
            : _hovered
            ? Color.alphaBlend(scheme.primary.withValues(alpha: 0.03), scheme.surfaceContainerLowest)
            : scheme.surfaceContainerLowest,
        borderRadius: radius,
        border: Border.all(
          color: done ? Colors.transparent : (_hovered ? scheme.outline.withValues(alpha: 0.5) : scheme.outlineVariant),
        ),
        boxShadow: !done && _hovered
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 3))]
            : const [],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CheckButton(done: done, priority: todo.priority, onTap: widget.onToggle, title: todo.title),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: theme.textTheme.bodyLarge!.copyWith(
                            color: done ? muted.withValues(alpha: 0.8) : scheme.onSurface,
                            fontWeight: done ? FontWeight.w400 : FontWeight.w500,
                            decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                            decorationColor: muted.withValues(alpha: 0.7),
                            height: 1.3,
                          ),
                          child: Text(todo.title),
                        ),
                        if (!done && todo.hasNotes) ...[
                          const SizedBox(height: 2),
                          Text(
                            todo.notes,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: muted),
                          ),
                        ],
                        ..._meta(context),
                      ],
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _hovered ? 1 : 0.55,
                  child: PopupMenuButton<String>(
                    tooltip: 'More',
                    icon: Icon(Icons.more_horiz, size: 18, color: muted),
                    onSelected: (v) => switch (v) {
                      'edit' => widget.onEdit(),
                      'toggle' => widget.onToggle(),
                      _ => widget.onDelete(),
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'toggle', child: Text(done ? 'Mark as active' : 'Mark as done')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: scheme.error)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Dismissible(
        key: ValueKey('dismiss-${todo.id}'),
        // Swipe right to toggle (the tile springs back), left to delete.
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            widget.onToggle();
            return false;
          }
          return true;
        },
        onDismissed: (_) => widget.onDelete(),
        background: _SwipeBackground(
          alignment: Alignment.centerLeft,
          color: scheme.primaryContainer,
          icon: done ? Icons.undo : Icons.check,
          iconColor: scheme.onPrimaryContainer,
        ),
        secondaryBackground: _SwipeBackground(
          alignment: Alignment.centerRight,
          color: scheme.errorContainer,
          icon: Icons.delete_outline,
          iconColor: scheme.onErrorContainer,
        ),
        child: card,
      ),
    );
  }

  List<Widget> _meta(BuildContext context) {
    final todo = widget.todo;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    if (todo.isDone) {
      if (todo.completedAt == null) return const [];
      return [
        const SizedBox(height: 4),
        Text(
          'Completed ${formatCompleted(todo.completedAt!, now)}',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.8)),
        ),
      ];
    }

    final pills = <Widget>[
      if (todo.dueDate != null)
        OptionPill(
          dense: true,
          icon: todo.isOverdue(now) ? Icons.error_outline : Icons.event_outlined,
          label: todo.isOverdue(now) ? 'Overdue · ${formatDue(todo.dueDate!, now)}' : formatDue(todo.dueDate!, now),
          color: todo.isOverdue(now)
              ? scheme.error
              : todo.isDueOn(now)
              ? scheme.primary
              : null,
        ),
      if (todo.priority != Priority.none)
        OptionPill(dense: true, icon: Icons.flag, label: todo.priority.label, color: todo.priority.color),
    ];
    if (pills.isEmpty) return const [];
    return [const SizedBox(height: 6), Wrap(spacing: 6, runSpacing: 4, children: pills)];
  }
}

class _CheckButton extends StatefulWidget {
  const _CheckButton({required this.done, required this.priority, required this.onTap, required this.title});

  final bool done;
  final Priority priority;
  final VoidCallback onTap;
  final String title;

  @override
  State<_CheckButton> createState() => _CheckButtonState();
}

class _CheckButtonState extends State<_CheckButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ring = widget.priority == Priority.none ? scheme.outline : widget.priority.color;
    final fill = scheme.primary;

    return Semantics(
      checked: widget.done,
      label: widget.done ? 'Mark "${widget.title}" as active' : 'Complete "${widget.title}"',
      button: true,
      child: InkResponse(
        onTap: widget.onTap,
        onHover: (h) => setState(() => _hovered = h),
        radius: 20,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.done
                    ? fill
                    : ring.withValues(alpha: _hovered ? 0.18 : (widget.priority == Priority.none ? 0 : 0.08)),
                border: Border.all(color: widget.done ? fill : ring, width: 2),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: widget.done
                    ? Icon(Icons.check, key: const ValueKey('on'), size: 14, color: scheme.onPrimary)
                    : _hovered
                    ? Icon(Icons.check, key: const ValueKey('hint'), size: 13, color: ring)
                    : const SizedBox.shrink(key: ValueKey('off')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({required this.alignment, required this.color, required this.icon, required this.iconColor});

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: color, borderRadius: Radii.lgAll),
      child: Icon(icon, color: iconColor),
    );
  }
}
