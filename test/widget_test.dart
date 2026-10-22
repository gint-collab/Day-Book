import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/app.dart';
import 'package:daybook/data/models/journal_entry.dart';
import 'package:daybook/data/models/priority.dart';
import 'package:daybook/data/repositories/journal_repository.dart';
import 'package:daybook/data/repositories/settings_repository.dart';
import 'package:daybook/data/repositories/todo_repository.dart';
import 'package:daybook/data/services/local_storage_service.dart';
import 'package:daybook/ui/core/widgets/chip_scroller.dart';
import 'package:daybook/ui/core/widgets/theme_toggle_button.dart';
import 'package:daybook/ui/journal/widgets/journal_entry_card.dart';
import 'package:daybook/ui/shell/glass_tab_bar.dart';
import 'package:daybook/ui/todos/view_models/todo_view_model.dart';
import 'package:daybook/ui/todos/widgets/todo_input.dart';
import 'package:provider/provider.dart';

/// In-memory storage so tests don't touch platform plugins.
class FakeStorage implements LocalStorageService {
  final _lists = <String, List<Map<String, dynamic>>>{};
  final _maps = <String, Map<String, dynamic>>{};

  @override
  Future<List<Map<String, dynamic>>> readList(String key) async => [...?_lists[key]];

  @override
  Future<void> writeList(String key, List<Map<String, dynamic>> items) async => _lists[key] = items;

  @override
  Future<Map<String, dynamic>?> readMap(String key) async => _maps[key];

  @override
  Future<void> writeMap(String key, Map<String, dynamic> value) async => _maps[key] = value;

  @override
  Future<void> remove(String key) async {
    _lists.remove(key);
    _maps.remove(key);
  }
}

/// Pumps the whole app at a given window size.
Future<void> pumpApp(WidgetTester tester, Size size, {FakeStorage? storage, TodoRepository? todos}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final s = storage ?? FakeStorage();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider(create: (_) => JournalRepository(s)),
        Provider.value(value: todos ?? TodoRepository(s)),
        Provider(create: (_) => SettingsRepository(s)),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

Brightness currentBrightness(WidgetTester tester) => Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

void main() {
  testWidgets('switches between Journal and To-dos and completes a task', (tester) async {
    await pumpApp(tester, const Size(1280, 1000));

    expect(find.text('Start your journal'), findsOneWidget);

    await tester.tap(find.text('To-dos').first);
    await tester.pumpAndSettle();
    expect(find.text('Nothing on your plate'), findsOneWidget);

    await tester.enterText(find.byKey(TodoInput.fieldKey), 'Buy milk');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('0 of 1 done'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Complete "Buy milk"'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 1 done'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);
  });

  group('responsive shell', () {
    testWidgets('phone: floating glass tab bar, no sidebar', (tester) async {
      await pumpApp(tester, const Size(390, 844));
      expect(find.byType(GlassTabBar), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Daybook'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet: icon rail without labels', (tester) async {
      await pumpApp(tester, const Size(900, 1000));
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Daybook'), findsNothing);
      expect(find.byTooltip('Journal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop: full sidebar that collapses', (tester) async {
      await pumpApp(tester, const Size(1400, 900));
      expect(find.text('Daybook'), findsOneWidget);
      await tester.tap(find.text('Collapse sidebar'));
      await tester.pumpAndSettle();
      expect(find.text('Daybook'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('theme toggle switches between light and dark', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    final before = currentBrightness(tester);
    await tester.tap(find.byType(ThemeToggleButton).first);
    await tester.pumpAndSettle();
    expect(currentBrightness(tester), isNot(before));
    await tester.tap(find.byType(ThemeToggleButton).first);
    await tester.pumpAndSettle();
    expect(currentBrightness(tester), before);
  });

  testWidgets('desktop split view: write an entry and see it in the list', (tester) async {
    await pumpApp(tester, const Size(1400, 900));
    await tester.tap(find.text('Write your first entry'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'First day');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    // The list (left) shows the entry, selected; the editor stays open (right).
    expect(find.text('First day'), findsWidgets);
    expect(find.text('Changes save automatically'), findsOneWidget);
    expect(find.text('1 entry'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4)); // let the toast expire
  });

  testWidgets('desktop: mood filter chips scroll with the mouse wheel', (tester) async {
    final storage = FakeStorage();
    await JournalRepository(storage).create(title: 'Hello', body: 'World');
    await pumpApp(tester, const Size(1400, 900), storage: storage);

    final chips = find.byType(ChipScroller);
    final scrollable = find.descendant(of: chips, matching: find.byType(Scrollable));
    ScrollPosition position() => tester.state<ScrollableState>(scrollable).position;
    expect(position().maxScrollExtent, greaterThan(0), reason: 'chips overflow the list column');

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(tester.getCenter(chips)));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
    await tester.pumpAndSettle();
    expect(position().pixels, greaterThan(0));
  });

  group('hashtags', () {
    test('are extracted from text and normalised', () {
      expect(JournalEntry.extractHashtags('Walk in the #Park with #family-time, #park again'), [
        'park',
        'family-time',
        'park',
      ]);
    });

    test('ignore C#, a#b, URL fragments and plain numbers', () {
      expect(JournalEntry.extractHashtags('Learning C# at site.com/page#top, a#b, issue #42'), isEmpty);
    });

    test('allTags merges explicit tags with inline hashtags, de-duplicated', () {
      final e = JournalEntry(
        id: '1',
        title: 'Day #one',
        body: 'Ran with #Work friends #work',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        tags: const ['work'],
      );
      expect(e.allTags, ['work', 'one']);
    });
  });

  testWidgets('preview shows tags, inline hashtags and a tag left uncommitted', (tester) async {
    await pumpApp(tester, const Size(1400, 900));
    await tester.tap(find.text('Write your first entry'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Morning');
    await tester.enterText(find.byType(TextField).at(2), 'Coffee with #friends');
    // Typed in the tag field but never confirmed with Enter or a comma.
    await tester.enterText(find.widgetWithText(TextField, 'Add tags — work, family…'), 'gratitude');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final card = find.byType(JournalEntryCard);
    expect(find.descendant(of: card, matching: find.text('#gratitude')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('#friends')), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('to-do editor: centred dialog on desktop, bottom sheet on phone', (tester) async {
    final storage = FakeStorage();
    final repo = TodoRepository(storage);
    await repo.create('Water plants');

    await pumpApp(tester, const Size(1400, 900), storage: storage, todos: repo);
    await tester.tap(find.text('To-dos').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Water plants'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    final dialog = tester.getRect(find.byType(Dialog));
    expect(dialog.center.dx, closeTo(700, 1), reason: 'centred horizontally');
    expect(dialog.center.dy, closeTo(450, 1), reason: 'centred vertically');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Water plants'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('to-do screen lays out at phone width without overflow', (tester) async {
    final storage = FakeStorage();
    final repo = TodoRepository(storage);
    await repo.create(
      'A long task name that should wrap nicely on a narrow phone screen',
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      priority: Priority.high,
    );
    final done = await repo.create('Finished thing');
    await repo.update(done.toggled());

    await pumpApp(tester, const Size(360, 780), storage: storage, todos: repo);
    await tester.tap(find.text('To-dos').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Overdue ·'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Finished thing'),
      200,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
    );
    expect(find.text('Finished thing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('TodoViewModel', () {
    late TodoViewModel vm;

    setUp(() async {
      vm = TodoViewModel(TodoRepository(FakeStorage()));
      await vm.load();
      final today = DateTime.now();
      await vm.add('Someday task');
      await vm.add('Due today', dueDate: today, priority: Priority.low);
      await vm.add('Late', dueDate: today.subtract(const Duration(days: 2)));
      await vm.add('Urgent later', dueDate: today.add(const Duration(days: 3)), priority: Priority.high);
    });

    test('smart sort puts overdue first and undated last', () {
      expect(vm.visibleActive.map((t) => t.title), ['Late', 'Due today', 'Urgent later', 'Someday task']);
    });

    test('priority sort puts high first', () {
      vm.setSort(TodoSort.priority);
      expect(vm.visibleActive.first.title, 'Urgent later');
    });

    test('due filters', () {
      vm.setDue(DueFilter.today);
      expect(vm.visibleActive.map((t) => t.title), ['Late', 'Due today']);
      vm.setDue(DueFilter.overdue);
      expect(vm.visibleActive.map((t) => t.title), ['Late']);
      vm.setDue(DueFilter.overdue); // toggles off
      expect(vm.due, DueFilter.any);
      expect(vm.overdueCount, 1);
      expect(vm.upcomingCount, 1);
    });

    test('completing moves a task to done and stamps completedAt', () async {
      final id = vm.visibleActive.first.id;
      await vm.toggle(id);
      expect(vm.visibleDone.single.completedAt, isNotNull);
      expect(vm.completedTodayCount, 1);
      vm.setStatus(TodoStatus.active);
      expect(vm.visibleDone, isEmpty);
    });

    test('clear completed can be undone', () async {
      await vm.toggle(vm.visibleActive.first.id);
      final removed = await vm.clearCompleted();
      expect(vm.totalCount, 3);
      await vm.restore(removed);
      expect(vm.totalCount, 4);
      expect(vm.doneCount, 1);
    });
  });
}
