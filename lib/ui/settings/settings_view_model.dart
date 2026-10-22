import 'package:flutter/material.dart';

import '../../data/repositories/settings_repository.dart';

/// App-wide preferences: light/dark theme and sidebar state.
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._repository) {
    _load();
  }

  final SettingsRepository _repository;

  ThemeMode _themeMode = ThemeMode.system;
  bool _sidebarCollapsed = false;

  ThemeMode get themeMode => _themeMode;
  bool get sidebarCollapsed => _sidebarCollapsed;

  /// Whether dark mode is currently showing, resolving "system" via
  /// [platformBrightness].
  bool isDark(Brightness platformBrightness) => switch (_themeMode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system => platformBrightness == Brightness.dark,
  };

  /// Flips between light and dark based on what's on screen right now.
  void toggleTheme(Brightness platformBrightness) =>
      setThemeMode(isDark(platformBrightness) ? ThemeMode.light : ThemeMode.dark);

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    _persist();
  }

  void toggleSidebar() {
    _sidebarCollapsed = !_sidebarCollapsed;
    notifyListeners();
    _persist();
  }

  Future<void> _load() async {
    final s = await _repository.load();
    _themeMode = s.themeMode;
    _sidebarCollapsed = s.sidebarCollapsed;
    notifyListeners();
  }

  Future<void> _persist() => _repository.save((themeMode: _themeMode, sidebarCollapsed: _sidebarCollapsed));
}
