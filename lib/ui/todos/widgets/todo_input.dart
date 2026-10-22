import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

import '../../../data/models/priority.dart';
import '../view_models/todo_composer_view_model.dart';
import 'due_dates.dart';
import 'option_pill.dart';

typedef TodoSubmit = void Function(String title, {DateTime? dueDate, Priority priority});

/// Quick-add composer: a title field plus inline due date and priority pills.
class TodoInput extends StatefulWidget {
  const TodoInput({super.key, required this.onSubmitted, this.focusNode});

  final TodoSubmit onSubmitted;

  /// Optional external focus node, so the screen can focus the composer.
  final FocusNode? focusNode;

  static const fieldKey = Key('todo-composer-field');

  @override
  State<TodoInput> createState() => _TodoInputState();
}

class _TodoInputState extends State<TodoInput> {
  final _vm = TodoComposerViewModel();
  final _controller = TextEditingController();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    _vm.addListener(() => setState(() {}));
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _vm.dispose();
    _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_vm.canSubmit) return;
    widget.onSubmitted(_vm.title, dueDate: _vm.due, priority: _vm.priority);
    _controller.clear();
    _vm.reset();
    _focusNode.requestFocus();
  }

  Future<void> _onDueSelected(Object choice) async {
    final DateTime? next = switch (choice) {
      DuePreset p => p.resolve(),
      'pick' => await pickDueDate(context, _vm.due),
      _ => null,
    };
    if (choice == 'pick' && next == null) return; // picker cancelled
    _vm.setDue(next);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = _focusNode.hasFocus || _vm.canSubmit;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: Radii.lgAll,
        border: Border.all(color: active ? scheme.primary.withValues(alpha: 0.6) : scheme.outlineVariant),
        boxShadow: active
            ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))]
            : const [],
      ),
      padding: const EdgeInsets.fromLTRB(6, 4, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.add_task, size: 20, color: active ? scheme.primary : scheme.onSurfaceVariant),
              ),
              Expanded(
                child: TextField(
                  key: TodoInput.fieldKey,
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _vm.setTitle,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Add a task…',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Add task',
                onPressed: _vm.canSubmit ? _submit : null,
                icon: const Icon(Icons.arrow_upward, size: 20),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                PopupMenuButton<Object>(
                  tooltip: 'Due date',
                  onSelected: _onDueSelected,
                  itemBuilder: (_) => [
                    for (final p in DuePreset.values)
                      PopupMenuItem(
                        value: p,
                        child: _MenuRow(icon: p.icon, label: p.label),
                      ),
                    const PopupMenuItem(
                      value: 'pick',
                      child: _MenuRow(icon: Icons.edit_calendar_outlined, label: 'Pick a date…'),
                    ),
                    if (_vm.due != null) ...[
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'clear',
                        child: _MenuRow(icon: Icons.event_busy_outlined, label: 'No date'),
                      ),
                    ],
                  ],
                  child: OptionPill(
                    icon: Icons.event_outlined,
                    label: _vm.due == null ? 'Due date' : formatDue(_vm.due!),
                    color: _vm.due == null ? null : scheme.primary,
                  ),
                ),
                PopupMenuButton<Priority>(
                  tooltip: 'Priority',
                  onSelected: (p) {
                    _vm.setPriority(p);
                    _focusNode.requestFocus();
                  },
                  itemBuilder: (_) => [
                    for (final p in Priority.values.reversed)
                      PopupMenuItem(
                        value: p,
                        child: _MenuRow(
                          icon: p == Priority.none ? Icons.outlined_flag : Icons.flag,
                          label: p.label,
                          color: p.color,
                          selected: p == _vm.priority,
                        ),
                      ),
                  ],
                  child: OptionPill(
                    icon: _vm.priority == Priority.none ? Icons.outlined_flag : Icons.flag,
                    label: _vm.priority == Priority.none ? 'Priority' : _vm.priority.label,
                    color: _vm.priority == Priority.none ? null : _vm.priority.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color, this.selected = false});

  final IconData icon;
  final String label;
  final Color? color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        if (selected) const Icon(Icons.check, size: 18),
      ],
    );
  }
}
