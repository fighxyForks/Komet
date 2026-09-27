import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/chat/chat_rebuild_slices.dart';
import 'package:komet/core/chat/chat_ui_state.dart';

void main() {
  testWidgets('высота поля и подсветка не пересобирают список', (tester) async {
    final messages = ValueNotifier(0);
    final readTime = ValueNotifier(0);
    final selection = ValueNotifier<Set<String>>(const {});
    final timestamps = ValueNotifier(false);
    final composer = ValueNotifier(40.0);
    final highlight = ValueNotifier<String?>(null);
    var listBuilds = 0;
    var composerBuilds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            ValueListenableBuilder<double>(
              valueListenable: composer,
              builder: (_, _, _) {
                composerBuilds++;
                return const SizedBox(height: 8);
              },
            ),
            ListenableBuilder(
              listenable: Listenable.merge(
                nativeTranscriptListenables(
                  messages: messages,
                  readTime: readTime,
                  selection: selection,
                  timestamps: timestamps,
                ),
              ),
              builder: (_, _) {
                listBuilds++;
                return const SizedBox(height: 8);
              },
            ),
          ],
        ),
      ),
    );

    final lists = listBuilds;
    final composers = composerBuilds;
    composer.value = 80;
    highlight.value = 'm1';
    await tester.pump();
    expect(listBuilds, lists);
    expect(composerBuilds, composers + 1);

    selection.value = {'m1'};
    await tester.pump();
    expect(listBuilds, lists + 1);
    expect(composerBuilds, composers + 1);
  });

  test('срез шифрования не уведомляет срез выделения', () {
    const initial = ChatUiState();
    final selection = ChatUiSelector((state) => state.selection, initial);
    final encryption = ChatUiSelector((state) => state.encryption, initial);
    var selectionNotes = 0;
    selection.addListener(() => selectionNotes++);
    final next = initial.copyWith(encryption: true);
    selection.apply(next);
    encryption.apply(next);
    expect(selectionNotes, 0);
    expect(encryption.value, isTrue);
  });
}
