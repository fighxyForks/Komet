import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/screens/chats/chat/message_highlighter.dart';

void main() {
  testWidgets('мигание включает и гасит подсветку несколько раз', (
    tester,
  ) async {
    final highlighter = MessageHighlighter(isMounted: () => true);
    addTearDown(highlighter.dispose);
    final states = <String?>[];
    highlighter.id.addListener(() => states.add(highlighter.id.value));

    highlighter.flash('m1');
    for (var i = 0; i < MessageHighlighter.flashCount * 2 + 1; i++) {
      await tester.pump(MessageHighlighter.flashPhase);
    }

    final ons = states.where((s) => s == 'm1').length;
    expect(ons, MessageHighlighter.flashCount);
    expect(highlighter.id.value, isNull);
  });

  testWidgets('удержание снимает подсветку по таймеру', (tester) async {
    final highlighter = MessageHighlighter(isMounted: () => true);
    addTearDown(highlighter.dispose);
    highlighter.hold('m2', const Duration(milliseconds: 500));
    expect(highlighter.id.value, 'm2');
    await tester.pump(const Duration(milliseconds: 600));
    expect(highlighter.id.value, isNull);
  });

  testWidgets('новое мигание прерывает прежнюю подсветку', (tester) async {
    final highlighter = MessageHighlighter(isMounted: () => true);
    addTearDown(highlighter.dispose);
    highlighter.hold('old', const Duration(seconds: 5));
    highlighter.flash('new');
    expect(highlighter.id.value, 'new');
    await tester.pump(const Duration(seconds: 6));
    expect(highlighter.id.value, isNull);
  });

  testWidgets('после закрытия чата мигание останавливается', (tester) async {
    var mounted = true;
    final highlighter = MessageHighlighter(isMounted: () => mounted);
    addTearDown(highlighter.dispose);
    highlighter.flash('m3');
    mounted = false;
    await tester.pump(const Duration(seconds: 3));
    expect(highlighter.id.value, 'm3');
  });
}
