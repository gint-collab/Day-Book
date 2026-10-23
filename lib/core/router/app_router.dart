import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../ui/about/views/about_screen.dart';
import '../../ui/journal/views/journal_workspace.dart';
import '../../ui/shell/app_shell.dart';
import '../../ui/todos/views/todo_screen.dart';

abstract final class Routes {
  static const journal = '/journal';
  static const journalNew = '/journal/new';
  static String journalEdit(String id) => '/journal/$id';
  static const todos = '/todos';

  /// Opens the to-do list with the quick-add field focused.
  static const todosCompose = '/todos?compose=1';

  /// Full-screen page pushed over the shell; open it with `context.push`.
  static const about = '/about';

  /// True when [path] shows a single journal entry (new or existing).
  static bool isJournalEditor(String path) => path.startsWith('$journal/');
}

/// All journal routes share this page key, so moving between the list and an
/// entry *updates* one page instead of stacking new ones. That lets the
/// workspace show list + editor side by side on wide screens while keeping
/// the list's scroll position and search text.
const _journalPageKey = ValueKey('journal-workspace');

Page<void> _journalPage({String? entryId, bool creating = false}) => NoTransitionPage(
  key: _journalPageKey,
  child: JournalWorkspace(selectedId: entryId, creating: creating),
);

/// Each tab is a [StatefulShellBranch], so it keeps its own location when
/// switching between Journal and To-dos.
GoRouter createRouter() => GoRouter(
  initialLocation: Routes.journal,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell, location: state.uri.path),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: Routes.journal, pageBuilder: (context, state) => _journalPage()),
            GoRoute(path: Routes.journalNew, pageBuilder: (context, state) => _journalPage(creating: true)),
            GoRoute(
              path: '${Routes.journal}/:id',
              pageBuilder: (context, state) => _journalPage(entryId: state.pathParameters['id']),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.todos,
              pageBuilder: (context, state) =>
                  NoTransitionPage(child: TodoScreen(compose: state.uri.queryParameters.containsKey('compose'))),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: Routes.about, builder: (context, state) => const AboutScreen()),
  ],
);
