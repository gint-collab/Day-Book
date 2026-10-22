import 'dart:async';
import 'dart:collection';

import 'package:uuid/uuid.dart';

import '../models/priority.dart';
import '../models/todo.dart';
import '../services/local_storage_service.dart';

/// Single source of truth for to-do items.
///
/// Keeps the loaded items in memory and announces every change on
/// [changes]. Edits update memory first so the UI responds instantly, then
/// write through to storage.
class TodoRepository {
  TodoRepository(this._storage);

  static const _key = 'todos';
  static const _uuid = Uuid();

  final LocalStorageService _storage;
  final _changes = StreamController<void>.broadcast(sync: true);

  List<Todo> _todos = [];

  /// Fires after the items change.
  Stream<void> get changes => _changes.stream;

  /// Items in memory, newest first.
  List<Todo> get todos => UnmodifiableListView(_todos);

  /// (Re)reads all items from storage.
  Future<void> load() async {
    _todos = await _readAll();
    _emit();
  }

  Future<Todo> create(String title, {String notes = '', DateTime? dueDate, Priority priority = Priority.none}) async {
    final todo = Todo(
      id: _uuid.v4(),
      title: title,
      notes: notes,
      createdAt: DateTime.now(),
      dueDate: dueDate == null ? null : Todo.dayOf(dueDate),
      priority: priority,
    );
    final todos = await _readAll();
    await _save([todo, ...todos]);
    _todos = [todo, ..._todos];
    _emit();
    return todo;
  }

  Future<void> update(Todo todo) async {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos = [..._todos]..[index] = todo;
      _emit();
    }
    final todos = await _readAll();
    await _save([for (final t in todos) t.id == todo.id ? todo : t]);
  }

  /// Returns the removed item (null if it wasn't loaded).
  Future<Todo?> delete(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    final removed = index == -1 ? null : _todos[index];
    if (removed != null) {
      _todos = [..._todos]..removeAt(index);
      _emit();
    }
    final todos = await _readAll();
    await _save(todos.where((t) => t.id != id).toList());
    return removed;
  }

  /// Returns the removed items.
  Future<List<Todo>> deleteCompleted() async {
    final removed = _todos.where((t) => t.isDone).toList();
    if (removed.isNotEmpty) {
      _todos = _todos.where((t) => !t.isDone).toList();
      _emit();
    }
    final todos = await _readAll();
    await _save(todos.where((t) => !t.isDone).toList());
    return removed;
  }

  /// Puts previously deleted items back (used by "Undo").
  Future<void> restore(List<Todo> items) async {
    final loaded = _todos.map((t) => t.id).toSet();
    _todos = [...items.where((t) => !loaded.contains(t.id)), ..._todos];
    _emit();
    final todos = await _readAll();
    final ids = todos.map((t) => t.id).toSet();
    await _save([...items.where((t) => !ids.contains(t.id)), ...todos]);
  }

  void dispose() => _changes.close();

  void _emit() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<List<Todo>> _readAll() async {
    final raw = await _storage.readList(_key);
    return raw.map(Todo.fromJson).toList();
  }

  Future<void> _save(List<Todo> todos) => _storage.writeList(_key, todos.map((t) => t.toJson()).toList());
}
