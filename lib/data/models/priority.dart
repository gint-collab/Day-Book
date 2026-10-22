import 'package:flutter/painting.dart';

/// How urgent a to-do is. Order matters: higher index = more urgent.
enum Priority {
  none('No priority', Color(0xFF8A8F98)),
  low('Low', Color(0xFF5E8FBF)),
  medium('Medium', Color(0xFFD08C3F)),
  high('High', Color(0xFFC95A5A));

  const Priority(this.label, this.color);

  final String label;
  final Color color;

  static Priority fromName(String? name) {
    for (final p in values) {
      if (p.name == name) return p;
    }
    return Priority.none;
  }
}
