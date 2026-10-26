import 'package:flutter/material.dart';

import '../../../data/models/todo_list_style.dart';
import '../../../data/repositories/settings_repository.dart';

/// App-wide preferences: light/dark theme, sidebar state and to-do list style.
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._repository) {
    _load();
  }

  final SettingsRepository _repository;

  ThemeMode _themeMode = ThemeMode.system;
  bool _sidebarCollapsed = false;
  TodoListStyle _todoListStyle = TodoListStyle.detailed;

  ThemeMode get themeMode => _themeMode;
  bool get sidebarCollapsed => _sidebarCollapsed;
  TodoListStyle get todoListStyle => _todoListStyle;

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

  void setTodoListStyle(TodoListStyle style) {
    if (style == _todoListStyle) return;
    _todoListStyle = style;
    notifyListeners();
    _persist();
  }

  Future<void> _load() async {
    final s = await _repository.load();
    _themeMode = s.themeMode;
    _sidebarCollapsed = s.sidebarCollapsed;
    _todoListStyle = s.todoListStyle;
    notifyListeners();
  }

  Future<void> _persist() => _repository.save(
    (themeMode: _themeMode, sidebarCollapsed: _sidebarCollapsed, todoListStyle: _todoListStyle),
  );
}
