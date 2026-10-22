import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../data/models/priority.dart';
import '../../../data/models/todo.dart';
import '../view_models/todo_editor_view_model.dart';
import 'due_dates.dart';

/// What the user chose in the editor sheet.
sealed class TodoEditResult {
  const TodoEditResult();
}

class TodoEdited extends TodoEditResult {
  const TodoEdited(this.todo);
  final Todo todo;
}

class TodoDeleteRequested extends TodoEditResult {
  const TodoDeleteRequested();
}

/// Opens the task editor (title, notes, due date, priority): a bottom sheet
/// on phones, a dialog centred on screen on tablets and desktops.
Future<TodoEditResult?> showTodoEditor(BuildContext context, Todo todo) {
  if (!WindowSize.of(context).isCompact) {
    return showDialog<TodoEditResult>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(Space.xl),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _TodoEditorSheet(todo: todo, inDialog: true),
        ),
      ),
    );
  }
  return showModalBottomSheet<TodoEditResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _TodoEditorSheet(todo: todo, inDialog: false),
  );
}

class _TodoEditorSheet extends StatefulWidget {
  const _TodoEditorSheet({required this.todo, required this.inDialog});

  final Todo todo;

  /// Dialog has no drag handle above the content, so it needs top padding.
  final bool inDialog;

  @override
  State<_TodoEditorSheet> createState() => _TodoEditorSheetState();
}

class _TodoEditorSheetState extends State<_TodoEditorSheet> {
  late final _vm = TodoEditorViewModel(widget.todo);
  late final _title = TextEditingController(text: widget.todo.title);
  late final _notes = TextEditingController(text: widget.todo.notes);

  @override
  void initState() {
    super.initState();
    _vm.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _vm.dispose();
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    final updated = _vm.result;
    if (updated != null) Navigator.pop(context, TodoEdited(updated));
  }

  Future<void> _pickCustom() async {
    final picked = await pickDueDate(context, _vm.due);
    if (picked != null) _vm.setDue(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final preset = _vm.duePreset;
    final isCustom = _vm.hasCustomDue;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(Space.xl, widget.inDialog ? Space.xl : 0, Space.xl, Space.xl - 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Edit task', style: theme.textTheme.titleMedium),
                const Spacer(),
                FilterChip(
                  avatar: Icon(_vm.done ? Icons.check_circle : Icons.radio_button_unchecked, size: 18),
                  showCheckmark: false,
                  label: Text(_vm.done ? 'Completed' : 'Mark done'),
                  selected: _vm.done,
                  onSelected: _vm.setDone,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              onChanged: _vm.setTitle,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.titleLarge,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                hintText: 'Task name',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notes,
              onChanged: _vm.setNotes,
              minLines: 2,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Add notes…',
                prefixIcon: Padding(padding: EdgeInsets.only(bottom: 22), child: Icon(Icons.notes, size: 20)),
              ),
            ),
            const SizedBox(height: 20),
            _Label('Due date'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in DuePreset.values)
                  ChoiceChip(
                    avatar: Icon(p.icon, size: 16),
                    label: Text(p.label),
                    selected: preset == p,
                    showCheckmark: false,
                    onSelected: (_) => _vm.setDue(p.resolve()),
                  ),
                ChoiceChip(
                  avatar: const Icon(Icons.edit_calendar_outlined, size: 16),
                  label: Text(isCustom ? DateFormat('EEE, MMM d').format(_vm.due!) : 'Pick date'),
                  selected: isCustom,
                  showCheckmark: false,
                  onSelected: (_) => _pickCustom(),
                ),
                ChoiceChip(
                  label: const Text('None'),
                  selected: _vm.due == null,
                  showCheckmark: false,
                  onSelected: (_) => _vm.setDue(null),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Label('Priority'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in Priority.values.reversed)
                  ChoiceChip(
                    avatar: Icon(p == Priority.none ? Icons.outlined_flag : Icons.flag, size: 16, color: p.color),
                    label: Text(p == Priority.none ? 'None' : p.label),
                    selected: _vm.priority == p,
                    showCheckmark: false,
                    selectedColor: p.color.withValues(alpha: 0.16),
                    side: BorderSide(color: _vm.priority == p ? p.color.withValues(alpha: 0.6) : scheme.outlineVariant),
                    onSelected: (_) => _vm.setPriority(p),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_vm.historyLabel, style: theme.textTheme.labelSmall?.copyWith(color: muted)),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context, const TodoDeleteRequested()),
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                ),
                const Spacer(),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 8),
                FilledButton(onPressed: _vm.canSave ? _save : null, child: const Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}
