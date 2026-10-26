import 'package:flutter/material.dart';

import '../models/todo_list_style.dart';
import '../services/local_storage_service.dart';

/// User preferences that should survive reloads.
typedef AppSettings = ({ThemeMode themeMode, bool sidebarCollapsed, TodoListStyle todoListStyle});

class SettingsRepository {
  SettingsRepository(this._storage);

  static const _key = 'settings';

  final LocalStorageService _storage;

  Future<AppSettings> load() async {
    final raw = await _storage.readMap(_key) ?? const {};
    final mode = ThemeMode.values.where((m) => m.name == raw['themeMode']).firstOrNull;
    final style = TodoListStyle.values.where((s) => s.name == raw['todoListStyle']).firstOrNull;
    return (
      themeMode: mode ?? ThemeMode.system,
      sidebarCollapsed: raw['sidebarCollapsed'] as bool? ?? false,
      todoListStyle: style ?? TodoListStyle.detailed,
    );
  }

  Future<void> save(AppSettings settings) => _storage.writeMap(_key, {
    'themeMode': settings.themeMode.name,
    'sidebarCollapsed': settings.sidebarCollapsed,
    'todoListStyle': settings.todoListStyle.name,
  });
}
