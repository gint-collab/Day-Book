import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/content_frame.dart';
import '../../core/widgets/page_header.dart';

/// What Dayloom does, where it keeps your data and how that data is
/// protected. Static content, so there is no view model.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ContentFrame(
        child: ListView(
          padding: EdgeInsets.fromLTRB(gutter, Space.lg, gutter, Space.xxxl + MediaQuery.paddingOf(context).bottom),
          children: const [
            _Hero(),
            SizedBox(height: Space.xl),
            _Section(
              icon: Icons.auto_awesome_outlined,
              title: 'What it does',
              children: [
                _Point(
                  icon: Icons.auto_stories_outlined,
                  title: 'Journal',
                  text:
                      'Write dated entries with a mood, tags (or inline #hashtags) and a note of '
                      'what you are grateful for. Search and filter by mood or tag.',
                ),
                _Point(
                  icon: Icons.check_circle_outline,
                  title: 'To-dos',
                  text:
                      'Quick-add tasks, then give them notes, a due date and a priority. Sort, '
                      'filter and clear finished tasks, with undo if you change your mind.',
                ),
                _Point(
                  icon: Icons.cloud_off_outlined,
                  title: 'Works offline',
                  text: 'Everything runs on your device. No account, no sign-in, no internet needed.',
                ),
              ],
            ),
            _Section(
              icon: Icons.save_outlined,
              title: 'How your data is saved',
              children: [
                _Point(
                  icon: Icons.phone_android_outlined,
                  title: 'On this device only',
                  text:
                      'Entries, tasks and settings are stored locally by the app. They are never '
                      'uploaded, and they do not sync between your devices.',
                ),
                _Point(
                  icon: Icons.bolt_outlined,
                  title: 'Saved automatically',
                  text:
                      'There is no save button. Tasks are saved the moment you change them, and '
                      'journal text is saved a moment after you stop typing. An unfinished new '
                      'entry is kept as a draft so you can pick up where you left off.',
                ),
                _Point(
                  icon: Icons.data_object,
                  title: 'Plain, readable format',
                  text:
                      'Data is kept as JSON text in four records: journal entries, the current '
                      'draft, to-dos, and your preferences (theme and sidebar).',
                ),
                SizedBox(height: Space.sm),
                _StorageLocations(),
              ],
            ),
            _Section(
              icon: Icons.shield_outlined,
              title: 'Privacy & security',
              children: [
                _Point(
                  icon: Icons.wifi_off_outlined,
                  title: 'No network access',
                  text:
                      'Dayloom has no servers and makes no network requests. The Android and '
                      'macOS release builds do not even ask for internet permission.',
                ),
                _Point(
                  icon: Icons.visibility_off_outlined,
                  title: 'No tracking',
                  text: 'No analytics, ads, crash reporting or third-party trackers. Nothing about you is collected.',
                ),
                _Point(
                  icon: Icons.lock_outline,
                  title: 'Protected by your device',
                  text:
                      'On Android, iOS and macOS the data sits in the app\'s private sandbox, '
                      'out of reach of other apps. Dayloom does not add its own encryption or '
                      'passcode, so anyone who can use your unlocked device or user account can '
                      'read it. Keep a screen lock on, and turn on disk encryption on computers.',
                ),
                _Point(
                  icon: Icons.backup_outlined,
                  title: 'Backups',
                  text:
                      'On Android, Dayloom opts out of cloud backup and device-to-device transfer. '
                      'On iOS and desktops, your system backups (such as iCloud or Time Machine) '
                      'may include the app\'s data.',
                ),
              ],
            ),
            _Section(
              icon: Icons.warning_amber_rounded,
              title: 'Good to know',
              children: [
                _Point(
                  icon: Icons.delete_outline,
                  title: 'Deleting is permanent',
                  text:
                      'A deleted entry is gone for good. Deleted or cleared tasks can be restored '
                      'with Undo, but only right after.',
                ),
                _Point(
                  icon: Icons.phonelink_erase_outlined,
                  title: 'Uninstalling erases everything',
                  text:
                      'Removing the app, clearing its storage, or clearing this site\'s data in '
                      'your browser deletes all entries and tasks. There is no copy anywhere else.',
                ),
              ],
            ),
            SizedBox(height: Space.sm),
            _Licenses(),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const AppLogo(size: 56),
        const SizedBox(width: Space.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dayloom', style: theme.textTheme.headlineSmall),
              const SizedBox(height: Space.xxs),
              Text(
                'A private journal and to-do list that lives on your device.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.children});

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Container(
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: Radii.lgAll,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: Space.sm),
                Eyebrow(title, color: scheme.onSurface),
              ],
            ),
            const SizedBox(height: Space.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// One fact: an icon, a bold lead-in and a sentence or two.
class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: Space.xxs),
                Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Platform {
  android('Android', 'App-private storage (Jetpack DataStore)'),
  apple('iOS & macOS', 'The app\'s own sandboxed preferences (NSUserDefaults)'),
  windows('Windows', 'shared_preferences.json in your user\'s AppData\\Roaming folder'),
  linux('Linux', 'shared_preferences.json in ~/.local/share'),
  web('Web', 'Your browser\'s localStorage for this site');

  const _Platform(this.label, this.location);

  final String label;
  final String location;

  static _Platform? get current {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS || TargetPlatform.macOS => apple,
      TargetPlatform.windows => windows,
      TargetPlatform.linux => linux,
      TargetPlatform.fuchsia => null,
    };
  }
}

/// Where the JSON ends up on each platform, with this device highlighted.
class _StorageLocations extends StatelessWidget {
  const _StorageLocations();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = _Platform.current;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: Radii.mdAll,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (final (i, p) in _Platform.values.indexed) ...[
            if (i > 0) const Divider(height: 1),
            Container(
              color: p == current ? scheme.primaryContainer.withValues(alpha: 0.5) : null,
              padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm + 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(p.label, style: theme.textTheme.labelLarge),
                  ),
                  Expanded(
                    child: Text(
                      p.location,
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  if (p == current) ...[
                    const SizedBox(width: Space.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 1),
                      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(Radii.pill)),
                      child: Text(
                        'This device',
                        style: theme.textTheme.labelSmall?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Licenses extends StatelessWidget {
  const _Licenses();

  @override
  Widget build(BuildContext context) {
    return Align(
      child: TextButton.icon(
        onPressed: () => showLicensePage(
          context: context,
          applicationName: 'Dayloom',
          applicationIcon: const Padding(padding: EdgeInsets.all(Space.sm), child: AppLogo(size: 48)),
        ),
        icon: const Icon(Icons.description_outlined, size: 18),
        label: const Text('Open-source licenses'),
      ),
    );
  }
}
