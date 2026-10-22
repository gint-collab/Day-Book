import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../data/models/priority.dart';
import '../../../data/models/todo.dart';
import '../widgets/due_dates.dart';

/// Form state for the task editor sheet. Nothing is written until the view
/// takes [result] and hands it back to the list.
class TodoEditorViewModel extends ChangeNotifier {
  TodoEditorViewModel(this.original)
    : _title = original.title,
      _notes = original.notes,
      _due = original.dueDate,
      _priority = original.priority,
      _done = original.isDone;

  /// The task as it was when the editor opened.
  final Todo original;

  String _title;
  String _notes;
  DateTime? _due;
  Priority _priority;
  bool _done;

  DateTime? get due => _due;
  Priority get priority => _priority;
  bool get done => _done;

  bool get canSave => _title.trim().isNotEmpty;

  /// The preset matching [due], if any.
  DuePreset? get duePreset => DuePreset.match(_due);

  /// A due date is set that isn't one of the presets.
  bool get hasCustomDue => _due != null && duePreset == null;

  /// "Created Mar 4, 2026 · completed today, 3:40 PM".
  String get historyLabel => [
    'Created ${DateFormat('MMM d, y').format(original.createdAt)}',
    if (original.completedAt != null && original.isDone) 'completed ${formatCompleted(original.completedAt!)}',
  ].join(' · ');

  void setTitle(String value) {
    final couldSave = canSave;
    _title = value;
    if (canSave != couldSave) notifyListeners();
  }

  void setNotes(String value) => _notes = value;

  void setDue(DateTime? value) {
    _due = value;
    notifyListeners();
  }

  void setPriority(Priority value) {
    _priority = value;
    notifyListeners();
  }

  void setDone(bool value) {
    _done = value;
    notifyListeners();
  }

  /// The edited task, or null when it can't be saved yet.
  Todo? get result {
    if (!canSave) return null;
    final updated = original.copyWith(title: _title, notes: _notes, dueDate: () => _due, priority: _priority);
    return _done != original.isDone ? updated.toggled() : updated;
  }
}
