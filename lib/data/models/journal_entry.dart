import 'package:flutter/foundation.dart';

import 'mood.dart';

/// A single journal entry. Immutable — use [copyWith] to derive changes.
///
/// [createdAt] is the day the entry is *about* and can be set by the user,
/// so past days can be logged after the fact.
@immutable
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.mood,
    this.tags = const [],
    this.gratitude = '',
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Mood? mood;
  final List<String> tags;
  final String gratitude;

  int get wordCount => countWords(body);

  /// Explicit [tags] plus any `#hashtags` written in the title, body or
  /// gratitude line — de-duplicated, in that order.
  List<String> get allTags => {...tags, ...extractHashtags('$title\n$body\n$gratitude')}.toList();

  static final _hashtag = RegExp(r'(?<![\p{L}\p{N}_#&/])#([\p{L}\p{N}_][\p{L}\p{N}_-]*)', unicode: true);

  /// Finds `#hashtags` in free text, normalised like tags (lowercase).
  /// Ignores things like "C#", "a#b" and URL fragments ("/page#top").
  static List<String> extractHashtags(String text) => [
    for (final m in _hashtag.allMatches(text))
      if (!RegExp(r'^\d+$').hasMatch(m.group(1)!)) normalizeTag(m.group(1)!), // "#1" isn't a tag
  ];

  /// The canonical form of a tag: lowercase, no '#', spaces/commas → '-'.
  static String normalizeTag(String raw) =>
      raw.trim().replaceAll(RegExp(r'^#+'), '').replaceAll(RegExp(r'[#,\s]+'), '-').toLowerCase();

  static int countWords(String text) {
    final t = text.trim();
    return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
  }

  JournalEntry copyWith({
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    Mood? Function()? mood,
    List<String>? tags,
    String? gratitude,
  }) {
    return JournalEntry(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // Wrapped in a function so callers can explicitly clear the mood.
      mood: mood != null ? mood() : this.mood,
      tags: tags ?? this.tags,
      gratitude: gratitude ?? this.gratitude,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'mood': mood?.name,
    'tags': tags,
    'gratitude': gratitude,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    mood: Mood.fromName(json['mood'] as String?),
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
    gratitude: json['gratitude'] as String? ?? '',
  );
}
