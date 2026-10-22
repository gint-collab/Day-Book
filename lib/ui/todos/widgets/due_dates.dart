import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/todo.dart';

/// Quick due-date presets shared by the composer and the editor sheet.
enum DuePreset {
  today('Today', Icons.today_outlined),
  tomorrow('Tomorrow', Icons.wb_sunny_outlined),
  nextWeek('Next week', Icons.date_range_outlined);

  const DuePreset(this.label, this.icon);
  final String label;
  final IconData icon;

  DateTime resolve([DateTime? from]) {
    final today = Todo.dayOf(from ?? DateTime.now());
    return switch (this) {
      DuePreset.today => today,
      DuePreset.tomorrow => today.add(const Duration(days: 1)),
      // The coming Monday (a full week out if today is Monday).
      DuePreset.nextWeek => today.add(Duration(days: 8 - today.weekday)),
    };
  }

  static DuePreset? match(DateTime? date) {
    if (date == null) return null;
    for (final p in values) {
      if (Todo.dayOf(date) == p.resolve()) return p;
    }
    return null;
  }
}

/// Opens the platform date picker for a due date (today onward is typical,
/// but past dates are allowed so overdue items can be re-dated honestly).
Future<DateTime?> pickDueDate(BuildContext context, DateTime? initial) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial ?? now,
    firstDate: DateTime(now.year - 2),
    lastDate: DateTime(now.year + 5),
    helpText: 'Due date',
  );
}

/// Human-friendly due label: "Today", "Tomorrow", "Yesterday", "Fri",
/// "Oct 30" or "Oct 30, 2027".
String formatDue(DateTime due, [DateTime? from]) {
  final today = Todo.dayOf(from ?? DateTime.now());
  final day = Todo.dayOf(due);
  final diff = day.difference(today).inDays;
  return switch (diff) {
    0 => 'Today',
    1 => 'Tomorrow',
    -1 => 'Yesterday',
    > 1 && < 7 => DateFormat('EEEE').format(day),
    _ when day.year == today.year => DateFormat('MMM d').format(day),
    _ => DateFormat('MMM d, y').format(day),
  };
}

/// "today, 3:40 PM" / "yesterday" / "Oct 12".
String formatCompleted(DateTime at, [DateTime? from]) {
  final today = Todo.dayOf(from ?? DateTime.now());
  final diff = today.difference(Todo.dayOf(at)).inDays;
  return switch (diff) {
    0 => 'today, ${DateFormat.jm().format(at)}',
    1 => 'yesterday',
    _ => DateFormat('MMM d').format(at),
  };
}
