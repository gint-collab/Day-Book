import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../data/models/todo.dart';

/// Plain add field for the simple checklist: a title and nothing else.
class SimpleTodoInput extends StatefulWidget {
  const SimpleTodoInput({super.key, required this.onSubmitted, this.focusNode});

  final ValueChanged<String> onSubmitted;

  /// Optional external focus node, so the screen can focus the field.
  final FocusNode? focusNode;

  static const fieldKey = Key('simple-todo-field');

  @override
  State<SimpleTodoInput> createState() => _SimpleTodoInputState();
}

class _SimpleTodoInputState extends State<SimpleTodoInput> {
  final _controller = TextEditingController();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    widget.onSubmitted(_controller.text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: SimpleTodoInput.fieldKey,
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        hintText: 'Add a task…',
        prefixIcon: const Icon(Icons.add, size: 20),
        suffixIcon: IconButton(
          tooltip: 'Add task',
          onPressed: _canSubmit ? _submit : null,
          icon: const Icon(Icons.keyboard_return, size: 18),
        ),
      ),
    );
  }
}

/// A checklist row: checkbox, title and a delete button.
class SimpleTodoTile extends StatelessWidget {
  const SimpleTodoTile({super.key, required this.todo, required this.onToggle, required this.onDelete});

  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final done = todo.isDone;

    return InkWell(
      borderRadius: Radii.mdAll,
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: done,
              onChanged: (_) => onToggle(),
              semanticLabel: done ? 'Mark "${todo.title}" as active' : 'Complete "${todo.title}"',
            ),
            const SizedBox(width: Space.xs),
            Expanded(
              child: Text(
                todo.title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: done ? muted : null,
                  decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                  decorationColor: muted,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: Icon(Icons.close, size: 18, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
