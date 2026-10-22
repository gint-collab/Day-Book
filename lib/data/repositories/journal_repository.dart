import 'package:uuid/uuid.dart';

import '../models/journal_draft.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';
import '../services/local_storage_service.dart';

/// Single source of truth for journal entries and the in-progress draft.
class JournalRepository {
  JournalRepository(this._storage);

  static const _key = 'journal_entries';
  static const _draftKey = 'journal_draft';
  static const _uuid = Uuid();

  final LocalStorageService _storage;

  Future<List<JournalEntry>> fetchAll() async {
    final raw = await _storage.readList(_key);
    final entries = raw.map(JournalEntry.fromJson).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<JournalEntry> create({
    required String title,
    required String body,
    DateTime? date,
    Mood? mood,
    List<String> tags = const [],
    String gratitude = '',
  }) async {
    final now = DateTime.now();
    final entry = JournalEntry(
      id: _uuid.v4(),
      title: title,
      body: body,
      createdAt: date ?? now,
      updatedAt: now,
      mood: mood,
      tags: tags,
      gratitude: gratitude,
    );
    final entries = await fetchAll();
    await _save([entry, ...entries]);
    return entry;
  }

  Future<JournalEntry> update(JournalEntry entry) async {
    final updated = entry.copyWith(updatedAt: DateTime.now());
    final entries = await fetchAll();
    await _save([for (final e in entries) e.id == entry.id ? updated : e]);
    return updated;
  }

  Future<void> delete(String id) async {
    final entries = await fetchAll();
    await _save(entries.where((e) => e.id != id).toList());
  }

  Future<JournalDraft?> loadDraft() async {
    final raw = await _storage.readMap(_draftKey);
    return raw == null ? null : JournalDraft.fromJson(raw);
  }

  Future<void> saveDraft(JournalDraft draft) =>
      draft.isEmpty ? _storage.remove(_draftKey) : _storage.writeMap(_draftKey, draft.toJson());

  Future<void> clearDraft() => _storage.remove(_draftKey);

  Future<void> _save(List<JournalEntry> entries) => _storage.writeList(_key, entries.map((e) => e.toJson()).toList());
}
