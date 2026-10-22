import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import 'journal_editor.dart';
import 'journal_list_pane.dart';

/// The journal section. With enough width it's a two-pane layout — entry
/// list on the left, editor on the right, like a notes app. On narrow
/// screens it shows one pane at a time.
class JournalWorkspace extends StatelessWidget {
  const JournalWorkspace({super.key, this.selectedId, this.creating = false});

  /// Entry open in the editor (from `/journal/:id`).
  final String? selectedId;

  /// The new-entry editor is open (from `/journal/new`).
  final bool creating;

  /// Minimum width of the section for list + editor side by side.
  static const splitBreakpoint = 840.0;

  bool get _editorOpen => creating || selectedId != null;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final split = constraints.maxWidth >= splitBreakpoint;
        final editor = _editorOpen
            ? JournalEditor(
                // A fresh editor (and view model) per entry.
                key: ValueKey(selectedId ?? 'new'),
                entryId: selectedId,
                showBack: !split,
              )
            : null;

        if (!split) {
          return AnimatedSwitcher(
            duration: Motion.medium,
            child: editor ?? const JournalListPane(key: ValueKey('list'), selectedId: null, inSplit: false),
          );
        }

        final listWidth = (constraints.maxWidth * 0.34).clamp(300.0, 400.0);
        return Row(
          children: [
            SizedBox(
              width: listWidth,
              child: JournalListPane(selectedId: selectedId, creating: creating, inSplit: true),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: editor ?? const _NoSelection()),
          ],
        );
      },
    );
  }
}

class _NoSelection extends StatelessWidget {
  const _NoSelection();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: EmptyState(
        icon: Icons.edit_note_rounded,
        title: 'Pick an entry',
        message: 'Choose an entry from the list, or start a new one.',
        action: FilledButton.icon(
          onPressed: () => context.go(Routes.journalNew),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New entry'),
        ),
      ),
    );
  }
}
