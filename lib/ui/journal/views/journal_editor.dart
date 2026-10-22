import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../core/widgets/content_frame.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_header.dart';
import '../view_models/journal_editor_view_model.dart';
import '../widgets/mood_picker.dart';
import '../widgets/tags_input.dart';

/// Create a new entry (no [entryId]) or edit an existing one.
///
/// Embedded in the journal workspace: full screen on phones ([showBack]),
/// or as the right-hand pane next to the entry list.
class JournalEditor extends StatelessWidget {
  const JournalEditor({super.key, this.entryId, this.showBack = true});

  final String? entryId;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => JournalEditorViewModel(repository: c.read(), journal: c.read(), entryId: entryId)..init(),
      child: _EditorView(showBack: showBack),
    );
  }
}

class _EditorView extends StatefulWidget {
  const _EditorView({required this.showBack});

  final bool showBack;

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  static const _prompts = [
    'What’s on your mind today?',
    'What made you smile today?',
    'What drained your energy, and what restored it?',
    'Describe a small moment you want to remember.',
    'What are you looking forward to?',
    'What would you tell yourself from this morning?',
    'What did you learn today?',
  ];

  final _title = TextEditingController();
  final _body = TextEditingController();
  final _gratitude = TextEditingController();
  bool _seeded = false;
  int _promptIndex = DateTime.now().day % _prompts.length;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _gratitude.dispose();
    super.dispose();
  }

  /// Copies loaded state into the text fields exactly once.
  void _seedControllers(JournalEditorViewModel vm) {
    _title.text = vm.title;
    _body.text = vm.body;
    _gratitude.text = vm.gratitude;
    _seeded = true;
  }

  void _close() => context.go(Routes.journal);

  Future<void> _save(JournalEditorViewModel vm) async {
    if (!vm.canSave) {
      showToast(context, 'Add a title or a few words first.');
      return;
    }
    final wasNew = !vm.isEditing;
    final saved = await vm.save();
    if (!mounted || saved == null) return;
    if (wasNew) {
      // Keep the new entry open, now as a regular (autosaving) entry.
      context.go(Routes.journalEdit(saved.id));
      showToast(context, 'Entry saved');
    }
  }

  Future<void> _delete(JournalEditorViewModel vm) async {
    final ok = await confirmAction(
      context,
      title: 'Delete this entry?',
      message: 'This can’t be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await vm.delete();
    if (!mounted) return;
    showToast(context, 'Entry deleted');
    _close();
  }

  Future<void> _discardDraft(JournalEditorViewModel vm) async {
    final ok = await confirmAction(
      context,
      title: 'Discard draft?',
      message: 'This clears everything you’ve written in this draft.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await vm.discardDraft();
    if (!mounted) return;
    showToast(context, 'Draft discarded');
    _close();
  }

  Future<void> _pickDate(JournalEditorViewModel vm) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.date.isAfter(now) ? now : vm.date,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      helpText: 'Which day is this entry about?',
    );
    if (picked != null) vm.setDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JournalEditorViewModel>();
    if (!vm.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (vm.notFound) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.find_in_page_outlined,
          title: 'Entry not found',
          message: 'It may have been deleted.',
          action: TextButton(onPressed: _close, child: const Text('Back to journal')),
        ),
      );
    }
    if (!_seeded) _seedControllers(vm);

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = WindowSize.of(context);
    final gutter = size.isCompact ? Space.lg + 4 : Space.xxl + 8;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => _save(vm),
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () => _save(vm),
        const SingleActivator(LogicalKeyboardKey.escape): _close,
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              _Toolbar(
                vm: vm,
                showBack: widget.showBack,
                onBack: _close,
                onSave: () => _save(vm),
                onDelete: () => _delete(vm),
                onDiscard: () => _discardDraft(vm),
              ),
              Expanded(
                child: ContentFrame(
                  maxWidth: 760,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(gutter, size.isCompact ? Space.xl : Space.xxl, gutter, Space.xxxl),
                    children: [
                      if (vm.restoredDraft)
                        const Padding(
                          padding: EdgeInsets.only(bottom: Space.lg),
                          child: _InfoBanner(icon: Icons.history, text: 'Restored your unsaved draft.'),
                        ),
                      Wrap(
                        spacing: Space.sm,
                        runSpacing: Space.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _MetaButton(
                            icon: Icons.calendar_today_outlined,
                            label: _formatDate(vm.date),
                            tooltip: 'Change the day this entry is about',
                            onTap: () => _pickDate(vm),
                          ),
                          if (vm.mood != null)
                            _MetaButton(
                              leading: Text(vm.mood!.emoji, style: const TextStyle(fontSize: 13)),
                              label: vm.mood!.label,
                              color: vm.mood!.color,
                            ),
                        ],
                      ),
                      const SizedBox(height: Space.lg),
                      TextField(
                        controller: _title,
                        onChanged: vm.setTitle,
                        autofocus: !vm.isEditing && vm.title.isEmpty,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                        style: (size.isCompact ? theme.textTheme.headlineMedium : theme.textTheme.headlineLarge),
                        decoration: _borderless.copyWith(hintText: 'Title'),
                      ),
                      const SizedBox(height: Space.sm),
                      TagsInput(
                        tags: vm.tags,
                        onAdd: vm.addTag,
                        onRemove: vm.removeTag,
                        onPendingChanged: vm.setPendingTag,
                      ),
                      const SizedBox(height: Space.lg),
                      const Divider(),
                      const SizedBox(height: Space.xl),
                      _SectionLabel(text: 'How are you feeling?'),
                      const SizedBox(height: Space.sm + 2),
                      MoodPicker(selected: vm.mood, onSelect: vm.setMood),
                      const SizedBox(height: Space.xl + 4),
                      _SectionLabel(
                        text: 'Entry',
                        trailing: TextButton.icon(
                          onPressed: () => setState(() => _promptIndex = (_promptIndex + 1) % _prompts.length),
                          icon: const Icon(Icons.auto_awesome_outlined, size: 15),
                          label: const Text('New prompt'),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        ),
                      ),
                      const SizedBox(height: Space.xs),
                      TextField(
                        controller: _body,
                        onChanged: vm.setBody,
                        maxLines: null,
                        minLines: 10,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.75),
                        decoration: _borderless.copyWith(hintText: _prompts[_promptIndex]),
                      ),
                      const SizedBox(height: Space.xl),
                      _GratitudeCallout(controller: _gratitude, onChanged: vm.setGratitude),
                    ],
                  ),
                ),
              ),
              _EditorFooter(wordCount: vm.wordCount, isEditing: vm.isEditing),
            ],
          ),
        ),
      ),
    );
  }

  static const _borderless = InputDecoration(
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    filled: false,
    isDense: true,
    contentPadding: EdgeInsets.zero,
  );

  static String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(d, now)) return 'Today, ${DateFormat('MMM d').format(d)}';
    if (DateUtils.isSameDay(d, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday, ${DateFormat('MMM d').format(d)}';
    }
    return DateFormat('EEE, MMM d, y').format(d);
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.vm,
    required this.showBack,
    required this.onBack,
    required this.onSave,
    required this.onDelete,
    required this.onDiscard,
  });

  final JournalEditorViewModel vm;
  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final compact = WindowSize.of(context).isCompact;
    final crumbStyle = theme.textTheme.labelLarge?.copyWith(color: muted);

    return Container(
      height: 56,
      padding: EdgeInsets.only(
        left: showBack ? Space.xs : Space.lg,
        right: vm.isEditing ? Space.sm : Space.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          if (showBack) IconButton(tooltip: 'Back to journal', icon: const Icon(Icons.arrow_back), onPressed: onBack),
          if (!compact) ...[
            Icon(Icons.auto_stories_outlined, size: 16, color: muted),
            const SizedBox(width: Space.sm),
            Text('Journal', style: crumbStyle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xs),
              child: Icon(Icons.chevron_right, size: 16, color: scheme.outline),
            ),
          ],
          Expanded(
            child: Text(
              vm.isEditing ? (vm.title.trim().isEmpty ? 'Untitled' : vm.title.trim()) : 'New entry',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          _StatusLabel(status: vm.status, compact: compact),
          if (vm.isEditing || vm.hasDraftContent)
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Icons.more_horiz),
              onSelected: (v) => v == 'delete' ? onDelete() : onDiscard(),
              itemBuilder: (_) => [
                if (vm.isEditing)
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_outline, color: scheme.error),
                      title: Text('Delete entry', style: TextStyle(color: scheme.error)),
                    ),
                  )
                else
                  const PopupMenuItem(
                    value: 'discard',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.restart_alt),
                      title: Text('Discard draft'),
                    ),
                  ),
              ],
            ),
          if (!vm.isEditing)
            Padding(
              padding: const EdgeInsets.only(left: Space.xs),
              child: FilledButton(onPressed: vm.status == SaveStatus.saving ? null : onSave, child: const Text('Save')),
            )
          else if (!showBack)
            IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: onBack),
        ],
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status, required this.compact});

  final SaveStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final (icon, text) = switch (status) {
      SaveStatus.idle => (null, ''),
      SaveStatus.pending => (Icons.more_horiz, 'Editing'),
      SaveStatus.saving => (Icons.sync, 'Saving…'),
      SaveStatus.saved => (Icons.check_circle_outline, 'Saved'),
      SaveStatus.draftSaved => (Icons.cloud_done_outlined, 'Draft saved'),
    };
    return AnimatedSwitcher(
      duration: Motion.medium,
      child: text.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              key: ValueKey(text),
              padding: const EdgeInsets.symmetric(horizontal: Space.sm),
              child: Tooltip(
                message: text,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: color),
                    if (!compact) ...[
                      const SizedBox(width: Space.xs + 2),
                      Text(text, style: theme.textTheme.labelMedium?.copyWith(color: color)),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _MetaButton extends StatelessWidget {
  const _MetaButton({this.icon, this.leading, required this.label, this.onTap, this.tooltip, this.color});

  final IconData? icon;
  final Widget? leading;
  final String label;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = color ?? scheme.onSurfaceVariant;
    final pill = Material(
      color: color?.withValues(alpha: 0.12) ?? scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(Radii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.md - 2, vertical: Space.xs + 1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 14, color: fg),
              ?leading,
              const SizedBox(width: Space.xs + 2),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? pill : Tooltip(message: tooltip!, child: pill);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 32, child: Row(children: [Eyebrow(text), const Spacer(), ?trailing]));
  }
}

class _GratitudeCallout extends StatelessWidget {
  const _GratitudeCallout({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.md + 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: Radii.mdAll,
        border: Border(left: BorderSide(color: scheme.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_rounded, size: 14, color: scheme.primary),
              const SizedBox(width: Space.sm - 2),
              Eyebrow('Grateful for', color: scheme.onPrimaryContainer),
            ],
          ),
          const SizedBox(height: Space.sm),
          TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.bodyMedium,
            decoration: _EditorViewState._borderless.copyWith(hintText: 'One thing, big or small…'),
          ),
        ],
      ),
    );
  }
}

class _EditorFooter extends StatelessWidget {
  const _EditorFooter({required this.wordCount, required this.isEditing});

  final int wordCount;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    final minutes = (wordCount / 200).ceil();
    final hint = isEditing ? 'Changes save automatically' : 'Ctrl/⌘ + S to save';

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Text('$wordCount ${wordCount == 1 ? 'word' : 'words'}', style: style),
          if (wordCount > 0) Text('  ·  $minutes min read', style: style),
          const Spacer(),
          if (!WindowSize.of(context).isCompact) Text(hint, style: style),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.md + 2, vertical: Space.sm + 2),
      decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: Radii.mdAll),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onTertiaryContainer),
          const SizedBox(width: Space.sm + 2),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onTertiaryContainer)),
          ),
        ],
      ),
    );
  }
}
