import 'package:flutter/foundation.dart';

import 'mood.dart';

/// Unsaved work-in-progress for a *new* entry, autosaved while typing so
/// nothing is lost on reload or accidental navigation.
@immutable
class JournalDraft {
  const JournalDraft({
    this.title = '',
    this.body = '',
    this.gratitude = '',
    this.mood,
    this.tags = const [],
    this.date,
  });

  final String title;
  final String body;
  final String gratitude;
  final Mood? mood;
  final List<String> tags;
  final DateTime? date;

  bool get isEmpty =>
      title.trim().isEmpty && body.trim().isEmpty && gratitude.trim().isEmpty && mood == null && tags.isEmpty;

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'gratitude': gratitude,
    'mood': mood?.name,
    'tags': tags,
    'date': date?.toIso8601String(),
  };

  factory JournalDraft.fromJson(Map<String, dynamic> json) => JournalDraft(
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    gratitude: json['gratitude'] as String? ?? '',
    mood: Mood.fromName(json['mood'] as String?),
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
    date: json['date'] == null ? null : DateTime.tryParse(json['date'] as String),
  );
}
