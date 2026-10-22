import 'package:flutter/material.dart';

import '../services/local_storage_service.dart';

/// User preferences that should survive reloads.
typedef AppSettings = ({ThemeMode themeMode, bool sidebarCollapsed});

class SettingsRepository {
  SettingsRepository(this._storage);

  static const _key = 'settings';

  final LocalStorageService _storage;

  Future<AppSettings> load() async {
    final raw = await _storage.readMap(_key) ?? const {};
    final mode = ThemeMode.values.where((m) => m.name == raw['themeMode']).firstOrNull;
    return (themeMode: mode ?? ThemeMode.system, sidebarCollapsed: raw['sidebarCollapsed'] as bool? ?? false);
  }

  Future<void> save(AppSettings settings) =>
      _storage.writeMap(_key, {'themeMode': settings.themeMode.name, 'sidebarCollapsed': settings.sidebarCollapsed});
}
