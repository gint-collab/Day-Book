import 'dart:async';
import 'dart:collection';

import 'package:uuid/uuid.dart';

import '../models/journal_draft.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';
import '../services/local_storage_service.dart';

/// Single source of truth for journal entries and the in-progress draft.
///
/// Keeps the loaded entries in memory and announces every change on
/// [changes], so all view models showing journal data stay in sync without
/// talking to each other.
class JournalRepository {
  JournalRepository(this._storage);

  static const _key = 'journal_entries';
  static const _draftKey = 'journal_draft';
  static const _uuid = Uuid();

  final LocalStorageService _storage;
  final _changes = StreamController<void>.broadcast(sync: true);

  List<JournalEntry> _entries = [];
  bool _hasDraft = false;
  Future<void>? _lastLoad;

  /// Fires after the entries or the draft flag change.
  Stream<void> get changes => _changes.stream;

  /// Entries in memory, newest first.
  List<JournalEntry> get entries => UnmodifiableListView(_entries);

  /// A new-entry draft is saved.
  bool get hasDraft => _hasDraft;

  /// Completes once entries have been loaded, starting a load if none has
  /// run yet. Never throws: whoever called [load] reports its errors.
  Future<void> get ready => (_lastLoad ?? load()).then<void>((_) {}, onError: (Object _) {});

  /// (Re)reads entries and the draft flag from storage.
  Future<void> load() => _lastLoad = _load();

  Future<void> _load() async {
    _entries = await _readAll();
    _hasDraft = await loadDraft() != null;
    _emit();
  }

  JournalEntry? findById(String id) {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
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
    final entries = await _readAll();
    await _save([entry, ...entries]);
    _upsert(entry);
    return entry;
  }

  Future<JournalEntry> update(JournalEntry entry) async {
    final updated = entry.copyWith(updatedAt: DateTime.now());
    final entries = await _readAll();
    await _save([for (final e in entries) e.id == entry.id ? updated : e]);
    _upsert(updated);
    return updated;
  }

  /// Removes the entry from memory right away, then from storage.
  Future<void> delete(String id) async {
    _entries = _entries.where((e) => e.id != id).toList();
    _emit();
    final entries = await _readAll();
    await _save(entries.where((e) => e.id != id).toList());
  }

  Future<JournalDraft?> loadDraft() async {
    final raw = await _storage.readMap(_draftKey);
    return raw == null ? null : JournalDraft.fromJson(raw);
  }

  Future<void> saveDraft(JournalDraft draft) async {
    await (draft.isEmpty ? _storage.remove(_draftKey) : _storage.writeMap(_draftKey, draft.toJson()));
    _setHasDraft(!draft.isEmpty);
  }

  Future<void> clearDraft() async {
    await _storage.remove(_draftKey);
    _setHasDraft(false);
  }

  void dispose() => _changes.close();

  /// Inserts or replaces [entry] in memory, keeping newest-first order.
  void _upsert(JournalEntry entry) {
    _entries = [
      for (final e in _entries)
        if (e.id != entry.id) e,
      entry,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _emit();
  }

  void _setHasDraft(bool value) {
    if (value == _hasDraft) return;
    _hasDraft = value;
    _emit();
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<List<JournalEntry>> _readAll() async {
    final raw = await _storage.readList(_key);
    return raw.map(JournalEntry.fromJson).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _save(List<JournalEntry> entries) => _storage.writeList(_key, entries.map((e) => e.toJson()).toList());
}
