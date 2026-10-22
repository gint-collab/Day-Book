import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/models/journal_draft.dart';
import '../../../data/models/journal_entry.dart';
import '../../../data/models/mood.dart';
import '../../../data/repositories/journal_repository.dart';
import 'journal_view_model.dart';

enum SaveStatus { idle, pending, saving, saved, draftSaved }

/// Form state for creating or editing a single entry.
///
/// * Existing entries autosave (debounced), like a notes app.
/// * New entries are kept as a draft (debounced) until the user saves, so
///   abandoned ideas don't litter the journal but work survives reloads.
class JournalEditorViewModel extends ChangeNotifier {
  JournalEditorViewModel({required this._repository, required this._journal, this.entryId});

  final JournalRepository _repository;
  final JournalViewModel _journal;
  final String? entryId;

  static const _debounce = Duration(milliseconds: 700);

  String _title = '';
  String _body = '';
  String _gratitude = '';
  Mood? _mood;
  List<String> _tags = [];
  DateTime _date = DateTime.now();

  bool _isReady = false;
  bool _restoredDraft = false;
  bool _notFound = false;
  SaveStatus _status = SaveStatus.idle;
  Timer? _timer;
  bool _disposed = false;

  bool get isEditing => entryId != null;
  bool get isReady => _isReady;
  bool get notFound => _notFound;
  bool get restoredDraft => _restoredDraft;
  SaveStatus get status => _status;

  String get title => _title;
  String get body => _body;
  String get gratitude => _gratitude;
  Mood? get mood => _mood;
  List<String> get tags => List.unmodifiable(_tags);
  DateTime get date => _date;
  int get wordCount => JournalEntry.countWords(_body);

  bool get canSave => _title.trim().isNotEmpty || _body.trim().isNotEmpty;

  /// The new-entry form has content worth keeping.
  bool get hasDraftContent => !isEditing && !_currentDraft().isEmpty;

  Future<void> init() async {
    if (isEditing) {
      // Deep links (e.g. reloading /journal/<id>) can arrive before the list loads.
      await _journal.ready;
      final existing = _journal.findById(entryId!);
      if (existing == null) {
        _notFound = true;
      } else {
        _title = existing.title;
        _body = existing.body;
        _gratitude = existing.gratitude;
        _mood = existing.mood;
        _tags = [...existing.tags];
        _date = existing.createdAt;
      }
    } else {
      final draft = await _repository.loadDraft();
      if (draft != null && !draft.isEmpty) {
        _title = draft.title;
        _body = draft.body;
        _gratitude = draft.gratitude;
        _mood = draft.mood;
        _tags = [...draft.tags];
        _date = draft.date ?? DateTime.now();
        _restoredDraft = true;
      }
    }
    _isReady = true;
    _notify();
  }

  // ---- Field updates --------------------------------------------------------

  void setTitle(String v) => _update(() => _title = v);
  void setBody(String v) => _update(() => _body = v);
  void setGratitude(String v) => _update(() => _gratitude = v);
  void setMood(Mood? m) => _update(() => _mood = _mood == m ? null : m);
  void setDate(DateTime d) => _update(() {
    // Keep the original time of day; only the calendar day changes.
    _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute);
  });

  void addTag(String raw) {
    final tag = JournalEntry.normalizeTag(raw);
    if (tag.isEmpty || _tags.contains(tag)) return;
    _update(() => _tags = [..._tags, tag]);
  }

  /// Text typed in the tag field but not committed yet (no Enter/comma).
  /// Committed on save and when the editor closes, so it isn't lost.
  String _pendingTag = '';
  void setPendingTag(String text) => _pendingTag = text;

  void _commitPendingTag() {
    if (_pendingTag.trim().isEmpty) return;
    final tag = JournalEntry.normalizeTag(_pendingTag);
    _pendingTag = '';
    if (tag.isNotEmpty && !_tags.contains(tag)) _tags = [..._tags, tag];
  }

  void removeTag(String tag) => _update(() => _tags = _tags.where((t) => t != tag).toList());

  void _update(VoidCallback change) {
    change();
    _status = SaveStatus.pending;
    _notify();
    _timer?.cancel();
    _timer = Timer(_debounce, isEditing ? _autosave : _saveDraft);
  }

  Future<void> _saveDraft() async {
    await _repository.saveDraft(_currentDraft());
    await _journal.refreshDraftFlag();
    if (_status == SaveStatus.pending) {
      _status = SaveStatus.draftSaved;
      _notify();
    }
  }

  Future<void> _autosave() async {
    // An entry emptied of title and body is left as-is rather than wiped.
    if (!canSave) return;
    _status = SaveStatus.saving;
    _notify();
    await _persistExisting();
    if (_status == SaveStatus.saving) {
      _status = SaveStatus.saved;
      _notify();
    }
  }

  Future<JournalEntry?> _persistExisting() async {
    final existing = _journal.findById(entryId!);
    if (existing == null) return null;
    final saved = await _repository.update(
      existing.copyWith(
        title: _title.trim(),
        body: _body.trim(),
        gratitude: _gratitude.trim(),
        mood: () => _mood,
        tags: _tags,
        createdAt: _date,
      ),
    );
    _journal.upsert(saved);
    return saved;
  }

  JournalDraft _currentDraft() =>
      JournalDraft(title: _title, body: _body, gratitude: _gratitude, mood: _mood, tags: _tags, date: _date);

  // ---- Commands -------------------------------------------------------------

  /// Saves now. For a new entry this creates it and returns it; for an
  /// existing one it flushes any pending autosave. Null if nothing to save.
  Future<JournalEntry?> save() async {
    if (!canSave) return null;
    _commitPendingTag();
    _timer?.cancel();
    _status = SaveStatus.saving;
    _notify();

    final JournalEntry? saved;
    if (isEditing) {
      saved = await _persistExisting();
    } else {
      saved = await _repository.create(
        title: _title.trim(),
        body: _body.trim(),
        gratitude: _gratitude.trim(),
        mood: _mood,
        tags: _tags,
        date: _date,
      );
      await _repository.clearDraft();
      await _journal.refreshDraftFlag();
      _journal.upsert(saved);
    }

    _status = SaveStatus.saved;
    _notify();
    return saved;
  }

  Future<void> discardDraft() async {
    _timer?.cancel();
    // Otherwise dispose() would commit it and write the draft back.
    _pendingTag = '';
    await _repository.clearDraft();
    await _journal.refreshDraftFlag();
    _title = _body = _gratitude = '';
    _mood = null;
    _tags = [];
    _date = DateTime.now();
    _restoredDraft = false;
    _status = SaveStatus.idle;
    _notify();
  }

  Future<void> delete() async {
    _timer?.cancel();
    if (entryId != null) await _journal.delete(entryId!);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    // Flush a pending write so the last keystrokes aren't lost when the
    // user switches entries or leaves the editor.
    final hadPendingTag = _pendingTag.trim().isNotEmpty;
    _commitPendingTag();
    if ((_timer?.isActive ?? false) || hadPendingTag) {
      _timer?.cancel();
      unawaited(isEditing ? (canSave ? _persistExisting() : Future.value()) : _saveDraft());
    }
    super.dispose();
  }
}
