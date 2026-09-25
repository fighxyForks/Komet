import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/backend/models/chat_folder.dart';
import 'package:komet/backend/modules/folders.dart';
import 'package:komet/frontend/screens/profile/folders_screen.dart';
import 'package:komet/main.dart' show api;

Future<void> _pump(WidgetTester tester, List<ChatFolder> folders) async {
  await tester.pumpWidget(
    MaterialApp(home: FoldersScreen(loader: () async => folders)),
  );
  await tester.pump();
}

void main() {
  setUpAll(() => api);

  testWidgets('lists user folders without the all-chats folder', (
    tester,
  ) async {
    await _pump(tester, const [
      ChatFolder(id: FoldersModule.allChatsFolderId, title: 'Все чаты'),
      ChatFolder(id: 'work', title: 'Работа', emoji: '💼'),
      ChatFolder(id: 'news', title: 'Новости'),
    ]);

    expect(find.byKey(const ValueKey('folders-create')), findsOneWidget);
    expect(find.text('Мои папки'), findsOneWidget);
    expect(find.byKey(const ValueKey('folder-work')), findsOneWidget);
    expect(find.byKey(const ValueKey('folder-news')), findsOneWidget);
    expect(find.text('💼'), findsOneWidget);
    expect(find.text('Все чаты'), findsNothing);
  });

  testWidgets('without folders only the create row is shown', (tester) async {
    await _pump(tester, const [
      ChatFolder(id: FoldersModule.allChatsFolderId, title: 'Все чаты'),
    ]);

    expect(find.byKey(const ValueKey('folders-create')), findsOneWidget);
    expect(find.text('Мои папки'), findsNothing);
  });

  testWidgets('reloads when folders change', (tester) async {
    var folders = const [ChatFolder(id: 'work', title: 'Работа')];
    await tester.pumpWidget(
      MaterialApp(home: FoldersScreen(loader: () async => folders)),
    );
    await tester.pump();
    expect(find.text('Работа'), findsOneWidget);

    folders = const [ChatFolder(id: 'home', title: 'Дом')];
    FoldersModule.revision.value++;
    await tester.pump();
    await tester.pump();
    expect(find.text('Работа'), findsNothing);
    expect(find.text('Дом'), findsOneWidget);
  });
}
