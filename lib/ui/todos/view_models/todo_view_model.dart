import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/models/priority.dart';
import '../../../data/models/todo.dart';
import '../../../data/repositories/todo_repository.dart';

/// Which completion state to show. [all] shows active tasks with a
/// separate "Completed" section underneath.
enum TodoStatus {
  all('All'),
  active('Active'),
  done('Done');

  const TodoStatus(this.label);
  final String label;
}

/// Filter by due date. [today] includes overdue tasks, like most planners.
enum DueFilter {
  any('Any time'),
  today('Today'),
  upcoming('Upcoming'),
  overdue('Overdue'),
  noDate('No date');

  const DueFilter(this.label);
  final String label;
}

enum TodoSort {
  smart('Smart'),
  dueDate('Due date'),
  priority('Priority'),
  newest('Newest'),
  title('A–Z');

  const TodoSort(this.label);
  final String label;
}

/// State for the to-do list: filters, sorting and derived counts.
///
/// Items come from [TodoRepository]; this rebuilds whenever it changes.
class TodoViewModel extends ChangeNotifier {
  TodoViewModel(this._repository) {
    _subscription = _repository.changes.listen((_) => notifyListeners());
    load();
  }

  final TodoRepository _repository;
  late final StreamSubscription<void> _subscription;

  List<Todo> get _todos => _repository.todos;
  bool _isLoading = false;
  String? _error;

  TodoStatus _status = TodoStatus.all;
  DueFilter _due = DueFilter.any;
  Priority? _priority;
  String _query = '';
  TodoSort _sort = TodoSort.smart;
  bool _completedExpanded = true;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _todos.isEmpty;
  TodoStatus get status => _status;
  DueFilter get due => _due;
  Priority? get priority => _priority;
  String get query => _query;
  TodoSort get sort => _sort;
  bool get completedExpanded => _completedExpanded;

  /// True when anything narrows the list beyond the status tabs.
  bool get isFiltering => _query.isNotEmpty || _due != DueFilter.any || _priority != null;

  // ---- Counts (unfiltered) --------------------------------------------------

  int get totalCount => _todos.length;
  int get activeCount => _todos.where((t) => !t.isDone).length;
  int get doneCount => _todos.where((t) => t.isDone).length;
  bool get hasCompleted => doneCount > 0;
  double get progress => _todos.isEmpty ? 0 : doneCount / _todos.length;
  int get progressPercent => (progress * 100).round();

  /// One-line encouragement under the progress ring.
  String get progressSummary => switch ((activeCount, completedTodayCount)) {
    (0, _) => 'Everything’s done. Nice work.',
    (_, 0) => '$activeCount to go — you’ve got this.',
    (_, final c) => '$c finished today · $activeCount to go',
  };

  int get overdueCount => _todos.where((t) => t.isOverdue(DateTime.now())).length;

  int get dueTodayCount {
    final now = DateTime.now();
    return _todos.where((t) => !t.isDone && t.isDueOn(now)).length;
  }

  int get upcomingCount {
    final today = Todo.dayOf(DateTime.now());
    return _todos.where((t) => !t.isDone && t.dueDate != null && t.dueDate!.isAfter(today)).length;
  }

  int get completedTodayCount {
    final now = DateTime.now();
    return _todos
        .where((t) => t.isDone && t.completedAt != null && Todo.dayOf(t.completedAt!) == Todo.dayOf(now))
        .length;
  }

  // ---- Visible lists --------------------------------------------------------

  List<Todo> get visibleActive =>
      _status == TodoStatus.done ? const [] : _sorted(_filtered(_todos.where((t) => !t.isDone)));

  /// Completed tasks, most recently finished first.
  List<Todo> get visibleDone {
    if (_status == TodoStatus.active) return const [];
    return _filtered(_todos.where((t) => t.isDone)).toList()
      ..sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
  }

  bool get hasVisible => visibleActive.isNotEmpty || visibleDone.isNotEmpty;

  /// Every task for the simple checklist, ignoring filters and sorting:
  /// open tasks newest first, then completed ones.
  List<Todo> get checklist {
    int byNewest(Todo a, Todo b) => b.createdAt.compareTo(a.createdAt);
    return [
      ..._todos.where((t) => !t.isDone).toList()..sort(byNewest),
      ..._todos.where((t) => t.isDone).toList()..sort(byNewest),
    ];
  }

  Iterable<Todo> _filtered(Iterable<Todo> source) {
    final now = DateTime.now();
    final today = Todo.dayOf(now);
    final q = _query.toLowerCase();
    return source.where((t) {
      if (_priority != null && t.priority != _priority) return false;
      final dueOk = switch (_due) {
        DueFilter.any => true,
        DueFilter.today => t.dueDate != null && !t.dueDate!.isAfter(today),
        DueFilter.upcoming => t.dueDate != null && t.dueDate!.isAfter(today),
        DueFilter.overdue => t.isOverdue(now),
        DueFilter.noDate => t.dueDate == null,
      };
      if (!dueOk) return false;
      return q.isEmpty || t.title.toLowerCase().contains(q) || t.notes.toLowerCase().contains(q);
    });
  }

  List<Todo> _sorted(Iterable<Todo> source) {
    int byDue(Todo a, Todo b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    }

    int byPriority(Todo a, Todo b) => b.priority.index.compareTo(a.priority.index);
    int byNewest(Todo a, Todo b) => b.createdAt.compareTo(a.createdAt);

    final comparators = switch (_sort) {
      TodoSort.smart => [byDue, byPriority, byNewest],
      TodoSort.dueDate => [byDue, byNewest],
      TodoSort.priority => [byPriority, byDue, byNewest],
      TodoSort.newest => [byNewest],
      TodoSort.title => [(Todo a, Todo b) => a.title.toLowerCase().compareTo(b.title.toLowerCase())],
    };
    return source.toList()..sort((a, b) {
      for (final c in comparators) {
        final r = c(a, b);
        if (r != 0) return r;
      }
      return 0;
    });
  }

  // ---- Filter commands ------------------------------------------------------

  void setStatus(TodoStatus value) {
    if (value == _status) return;
    _status = value;
    notifyListeners();
  }

  /// Selecting the active due filter again turns it off.
  void setDue(DueFilter value) {
    _due = _due == value ? DueFilter.any : value;
    notifyListeners();
  }

  void setPriority(Priority value) {
    _priority = _priority == value ? null : value;
    notifyListeners();
  }

  void setQuery(String value) {
    final q = value.trim();
    if (q == _query) return;
    _query = q;
    notifyListeners();
  }

  void setSort(TodoSort value) {
    if (value == _sort) return;
    _sort = value;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _due = DueFilter.any;
    _priority = null;
    notifyListeners();
  }

  void toggleCompletedExpanded() {
    _completedExpanded = !_completedExpanded;
    notifyListeners();
  }

  // ---- Data commands --------------------------------------------------------

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.load();
    } catch (e, st) {
      debugPrint('Failed to load to-dos: $e\n$st');
      _error = 'Could not load your to-dos.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(String title, {DateTime? dueDate, Priority priority = Priority.none}) async {
    final clean = title.trim();
    if (clean.isEmpty) return;
    await _repository.create(clean, dueDate: dueDate, priority: priority);
  }

  Future<void> toggle(String id) async {
    final todo = _find(id);
    if (todo == null) return;
    await _repository.update(todo.toggled());
  }

  Future<void> update(Todo todo) async {
    if (_find(todo.id) == null) return;
    await _repository.update(
      todo.copyWith(
        title: todo.title.trim(),
        notes: todo.notes.trim(),
        dueDate: () => todo.dueDate == null ? null : Todo.dayOf(todo.dueDate!),
      ),
    );
  }

  /// Returns the removed item so the view can offer "Undo".
  Future<Todo?> delete(String id) async {
    if (_find(id) == null) return null;
    return _repository.delete(id);
  }

  /// Returns the removed items so the view can offer "Undo".
  Future<List<Todo>> clearCompleted() async {
    if (!hasCompleted) return const [];
    return _repository.deleteCompleted();
  }

  Future<void> restore(List<Todo> items) => _repository.restore(items);

  Todo? _find(String id) {
    for (final t in _todos) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
