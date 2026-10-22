import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/journal_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/todo_repository.dart';
import 'data/services/local_storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = LocalStorageService();

  runApp(
    // Dependency graph: Service -> Repositories -> (ViewModels, created in App).
    MultiProvider(
      providers: [
        Provider(create: (_) => JournalRepository(storage)),
        Provider(create: (_) => TodoRepository(storage)),
        Provider(create: (_) => SettingsRepository(storage)),
      ],
      child: const App(),
    ),
  );
}
