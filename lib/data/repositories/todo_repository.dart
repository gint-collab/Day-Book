import 'package:uuid/uuid.dart';

import '../models/priority.dart';
import '../models/todo.dart';
import '../services/local_storage_service.dart';

/// Single source of truth for to-do items.
class TodoRepository {
  TodoRepository(this._storage);

  static const _key = 'todos';
  static const _uuid = Uuid();

  final LocalStorageService _storage;

  Future<List<Todo>> fetchAll() async {
    final raw = await _storage.readList(_key);
    return raw.map(Todo.fromJson).toList();
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
    final todos = await fetchAll();
    await _save([todo, ...todos]);
    return todo;
  }

  Future<void> update(Todo todo) async {
    final todos = await fetchAll();
    await _save([for (final t in todos) t.id == todo.id ? todo : t]);
  }

  Future<void> delete(String id) async {
    final todos = await fetchAll();
    await _save(todos.where((t) => t.id != id).toList());
  }

  Future<void> deleteCompleted() async {
    final todos = await fetchAll();
    await _save(todos.where((t) => !t.isDone).toList());
  }

  /// Puts previously deleted items back (used by "Undo").
  Future<void> restore(List<Todo> items) async {
    final todos = await fetchAll();
    final ids = todos.map((t) => t.id).toSet();
    await _save([...items.where((t) => !ids.contains(t.id)), ...todos]);
  }

  Future<void> _save(List<Todo> todos) => _storage.writeList(_key, todos.map((t) => t.toJson()).toList());
}
