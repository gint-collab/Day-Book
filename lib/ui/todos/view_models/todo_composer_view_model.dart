import 'package:flutter/foundation.dart';

import '../../../data/models/priority.dart';

/// Form state for the quick-add composer: the typed title plus the due date
/// and priority picked from its pills.
class TodoComposerViewModel extends ChangeNotifier {
  String _title = '';
  DateTime? _due;
  Priority _priority = Priority.none;

  String get title => _title;
  DateTime? get due => _due;
  Priority get priority => _priority;

  bool get canSubmit => _title.trim().isNotEmpty;

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setDue(DateTime? value) {
    _due = value;
    notifyListeners();
  }

  void setPriority(Priority value) {
    _priority = value;
    notifyListeners();
  }

  /// Clears the form after a task is added.
  void reset() {
    _title = '';
    _due = null;
    _priority = Priority.none;
    notifyListeners();
  }
}
