import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'ui/journal/view_models/journal_view_model.dart';
import 'ui/settings/view_models/settings_view_model.dart';
import 'ui/todos/view_models/todo_view_model.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // One router per app instance (keeps tests isolated from each other).
  final _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ViewModels live above the router so state survives tab switches.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (c) => SettingsViewModel(c.read())),
        ChangeNotifierProvider(create: (c) => JournalViewModel(c.read())),
        ChangeNotifierProvider(create: (c) => TodoViewModel(c.read())),
      ],
      child: Builder(
        builder: (context) => MaterialApp.router(
          title: 'Daybook',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: context.select((SettingsViewModel s) => s.themeMode),
          themeAnimationDuration: const Duration(milliseconds: 250),
          routerConfig: _router,
          // Tapping outside a text field dismisses the keyboard.
          builder: (context, child) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child,
          ),
        ),
      ),
    );
  }
}
