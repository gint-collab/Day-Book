import 'package:flutter/material.dart';

/// Five-point mood scale, ordered worst → best so [index] doubles as a score.
enum Mood {
  awful('Awful', '😞', Color(0xFFC26D6D)),
  low('Low', '😕', Color(0xFFC9925A)),
  okay('Okay', '😐', Color(0xFFB3A15C)),
  good('Good', '🙂', Color(0xFF6FA582)),
  great('Great', '😄', Color(0xFF5E8FBF));

  const Mood(this.label, this.emoji, this.color);

  final String label;
  final String emoji;
  final Color color;

  /// 1 (awful) to 5 (great).
  int get score => index + 1;

  static Mood? fromName(String? name) {
    for (final m in values) {
      if (m.name == name) return m;
    }
    return null;
  }
}
