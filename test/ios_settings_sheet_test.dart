import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/settings/ios_settings_model.dart';
import 'package:komet/frontend/settings/ios_settings_row.dart';

void main() {
  const entries = [
    IosSettingsEntry(
      id: 'haptics',
      title: 'Тактильный отклик',
      section: 'Приложение',
      keywords: ['вибрация'],
    ),
    IosSettingsEntry(id: 'folders', title: 'Папки', section: 'Чаты'),
  ];

  test('empty query does not list search hits', () {
    expect(filterIosSettings(entries, '   '), isEmpty);
  });

  test('search matches a title and a keyword', () {
    expect(filterIosSettings(entries, 'папк').map((hit) => hit.entry.id), [
      'folders',
    ]);
    expect(filterIosSettings(entries, 'вибра').map((hit) => hit.entry.id), [
      'haptics',
    ]);
  });

  test('search matches the section name', () {
    expect(
      filterIosSettings(entries, 'приложение').map((hit) => hit.entry.id),
      ['haptics'],
    );
  });

  testWidgets('a settings row shows its title and trailing value', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IosSettingsRow(
          title: 'Язык приложения',
          icon: Icons.language,
          trailing: 'русский',
          onTap: () {},
        ),
      ),
    );
    expect(find.text('Язык приложения'), findsOneWidget);
    expect(find.text('русский'), findsOneWidget);
  });

  testWidgets('a section shows its sentence-case header', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: IosSettingsSection(
          header: 'Приложение',
          children: [Text('Уведомления')],
        ),
      ),
    );
    expect(find.text('Приложение'), findsOneWidget);
    expect(find.text('Уведомления'), findsOneWidget);
  });

  testWidgets('search results name the section under the row', (tester) async {
    final hits = filterIosSettings(entries, 'папки');
    await tester.pumpWidget(
      MaterialApp(
        home: IosSettingsRow(
          title: hits.single.entry.title,
          icon: Icons.folder,
          section: hits.single.entry.section,
        ),
      ),
    );
    expect(find.text('Папки'), findsOneWidget);
    expect(find.text('Чаты'), findsOneWidget);
  });
}
