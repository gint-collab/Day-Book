import 'package:flutter/foundation.dart';

import 'priority.dart';

/// A single to-do item. Immutable — use [copyWith] to derive changes.
@immutable
class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.createdAt,
    this.notes = '',
    this.isDone = false,
    this.completedAt,
    this.dueDate,
    this.priority = Priority.none,
  });

  final String id;
  final String title;
  final String notes;
  final bool isDone;
  final DateTime createdAt;
  final DateTime? completedAt;

  /// Calendar day the task is due (time of day is ignored).
  final DateTime? dueDate;
  final Priority priority;

  bool get hasNotes => notes.trim().isNotEmpty;

  bool isOverdue(DateTime now) => !isDone && dueDate != null && dayOf(dueDate!).isBefore(dayOf(now));

  bool isDueOn(DateTime day) => dueDate != null && dayOf(dueDate!) == dayOf(day);

  /// Toggles completion, stamping or clearing [completedAt].
  Todo toggled() => copyWith(isDone: !isDone, completedAt: () => isDone ? null : DateTime.now());

  /// Nullable fields take a closure so callers can explicitly clear them.
  Todo copyWith({
    String? title,
    String? notes,
    bool? isDone,
    DateTime? Function()? completedAt,
    DateTime? Function()? dueDate,
    Priority? priority,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
      completedAt: completedAt != null ? completedAt() : this.completedAt,
      dueDate: dueDate != null ? dueDate() : this.dueDate,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'notes': notes,
    'isDone': isDone,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'priority': priority.name,
  };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    isDone: json['isDone'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    dueDate: DateTime.tryParse(json['dueDate'] as String? ?? ''),
    priority: Priority.fromName(json['priority'] as String?),
  );

  static DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
}
