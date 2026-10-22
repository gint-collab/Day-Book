import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../data/models/journal_entry.dart';
import '../../../data/models/mood.dart';
import '../../../data/repositories/journal_repository.dart';

/// A labelled bucket of entries for the grouped list ("Today", "March 2026"…).
typedef EntryGroup = ({String label, List<JournalEntry> entries});

/// State for the journal list: entries, search/filter, and derived stats.
///
/// Entries come from [JournalRepository]; this rebuilds whenever it changes.
class JournalViewModel extends ChangeNotifier {
  JournalViewModel(this._repository) {
    _subscription = _repository.changes.listen((_) => notifyListeners());
    load();
  }

  final JournalRepository _repository;
  late final StreamSubscription<void> _subscription;

  bool _isLoading = false;
  String? _error;
  String _query = '';
  Mood? _moodFilter;
  String? _tagFilter;

  List<JournalEntry> get _entries => _repository.entries;

  List<JournalEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _entries.isEmpty;
  String get query => _query;
  Mood? get moodFilter => _moodFilter;
  String? get tagFilter => _tagFilter;
  bool get isFiltering => _query.isNotEmpty || _moodFilter != null || _tagFilter != null;
  bool get hasDraft => _repository.hasDraft;

  // ---- Derived: filtering & grouping ---------------------------------------

  List<JournalEntry> get filteredEntries {
    final q = _query.toLowerCase();
    return _entries.where((e) {
      if (_moodFilter != null && e.mood != _moodFilter) return false;
      if (_tagFilter != null && !e.allTags.contains(_tagFilter)) return false;
      if (q.isEmpty) return true;
      return e.title.toLowerCase().contains(q) ||
          e.body.toLowerCase().contains(q) ||
          e.gratitude.toLowerCase().contains(q) ||
          e.allTags.any((t) => t.contains(q));
    }).toList();
  }

  List<EntryGroup> get groupedEntries {
    final today = _dayOf(DateTime.now());
    final groups = <String, List<JournalEntry>>{};
    for (final e in filteredEntries) {
      final day = _dayOf(e.createdAt);
      final diff = today.difference(day).inDays;
      final label = switch (diff) {
        0 => 'Today',
        1 => 'Yesterday',
        < 7 && >= 0 => 'Earlier this week',
        _ => DateFormat('MMMM yyyy').format(day),
      };
      groups.putIfAbsent(label, () => []).add(e);
    }
    return [for (final g in groups.entries) (label: g.key, entries: g.value)];
  }

  /// Every tag in use with how many entries carry it, most used first.
  List<({String tag, int count})> get allTags {
    final counts = <String, int>{};
    for (final e in _entries) {
      for (final t in e.allTags) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final list = [for (final c in counts.entries) (tag: c.key, count: c.value)];
    list.sort((a, b) => b.count != a.count ? b.count.compareTo(a.count) : a.tag.compareTo(b.tag));
    return list;
  }

  // ---- Derived: stats -------------------------------------------------------

  int get totalWords => _entries.fold(0, (sum, e) => sum + e.wordCount);

  /// Consecutive days with at least one entry, ending today — or yesterday,
  /// so the streak isn't shown as broken before you've written today.
  int get streak {
    final days = _entries.map((e) => _dayOf(e.createdAt)).toSet();
    var cursor = _dayOf(DateTime.now());
    if (!days.contains(cursor)) cursor = cursor.subtract(const Duration(days: 1));
    var count = 0;
    while (days.contains(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  bool get wroteToday {
    final today = _dayOf(DateTime.now());
    return _entries.any((e) => _dayOf(e.createdAt) == today);
  }

  /// The last 7 days, oldest first, each with the average mood logged that
  /// day (or null when nothing was logged).
  List<({DateTime day, Mood? mood})> get weekMoods {
    final today = _dayOf(DateTime.now());
    return [
      for (var i = 6; i >= 0; i--)
        () {
          final day = today.subtract(Duration(days: i));
          final scores = _entries
              .where((e) => e.mood != null && _dayOf(e.createdAt) == day)
              .map((e) => e.mood!.index)
              .toList();
          final mood = scores.isEmpty ? null : Mood.values[(scores.reduce((a, b) => a + b) / scores.length).round()];
          return (day: day, mood: mood);
        }(),
    ];
  }

  /// Average mood across the last 7 days, or null if none logged.
  Mood? get weekAverageMood {
    final logged = weekMoods.map((d) => d.mood).whereType<Mood>().toList();
    if (logged.isEmpty) return null;
    final avg = logged.map((m) => m.index).reduce((a, b) => a + b) / logged.length;
    return Mood.values[avg.round()];
  }

  // ---- Commands -------------------------------------------------------------

  void setQuery(String value) {
    final q = value.trim();
    if (q == _query) return;
    _query = q;
    notifyListeners();
  }

  void setMoodFilter(Mood? mood) {
    _moodFilter = _moodFilter == mood ? null : mood;
    notifyListeners();
  }

  void setTagFilter(String? tag) {
    _tagFilter = _tagFilter == tag ? null : tag;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _moodFilter = null;
    _tagFilter = null;
    notifyListeners();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.load();
    } catch (e, st) {
      debugPrint('Failed to load journal entries: $e\n$st');
      _error = 'Could not load journal entries.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
}
