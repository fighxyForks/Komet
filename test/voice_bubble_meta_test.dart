import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/backend/modules/messages.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/core/utils/format.dart';
import 'package:komet/frontend/widgets/attachment/bubbles/ios_bubble_metrics.dart';
import 'package:komet/frontend/widgets/attachment/bubbles/voice_bubble.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _time = DateTime(2026, 9, 24, 18, 15).millisecondsSinceEpoch;

Widget _bubble({
  required bool showMeta,
  int? audioId = 42,
  bool ios = false,
  bool isMe = false,
}) {
  final child = VoiceMessageBubble(
    duration: 27,
    url: '',
    textColor: Colors.white,
    isMe: isMe,
    showMeta: showMeta,
    time: _time,
    cs: const ColorScheme.dark(primary: Color(0xFF4082E6)),
    chatId: 1,
    messageId: '1',
    senderId: 2,
    audioId: audioId,
    waveData: String.fromCharCodes([10, 40, 80, 20, 60, 90, 30, 50]),
  );
  final app = MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(primary: Color(0xFF4082E6)),
    ),
    home: Scaffold(body: child),
  );
  return ios ? IosGlass(child: app) : app;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TranscriptionCache.clear();
    AppIosGlass.debugReset();
  });

  tearDown(() {
    TranscriptionCache.clear();
    AppIosGlass.debugReset();
  });

  testWidgets('время голосового рисуется в самом бабле без реакций', (
    tester,
  ) async {
    await tester.pumpWidget(_bubble(showMeta: true));
    expect(
      find.text(formatClock(DateTime.fromMillisecondsSinceEpoch(_time))),
      findsOneWidget,
    );
  });

  testWidgets('с реакциями время уходит в футер и не дублируется', (
    tester,
  ) async {
    await tester.pumpWidget(_bubble(showMeta: false));
    expect(
      find.text(formatClock(DateTime.fromMillisecondsSinceEpoch(_time))),
      findsNothing,
    );
  });

  testWidgets('кнопка плей — залитый круг 44pt', (tester) async {
    await tester.pumpWidget(_bubble(showMeta: true));
    final play = find.byKey(const ValueKey('voice-play'));
    expect(play, findsOneWidget);
    expect(tester.getSize(play), const Size(44, 44));
  });

  testWidgets('свёрнутая расшифровка показывает →Т', (tester) async {
    await tester.pumpWidget(_bubble(showMeta: true, audioId: 7));
    expect(
      find.byKey(const ValueKey('voice-transcribe-collapsed')),
      findsOneWidget,
    );
    expect(find.text('→Т'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('voice-transcribe-expanded')),
      findsNothing,
    );
  });

  testWidgets('без audioId кнопка расшифровки скрыта', (tester) async {
    await tester.pumpWidget(_bubble(showMeta: true, audioId: null));
    expect(
      find.byKey(const ValueKey('voice-transcribe-collapsed')),
      findsNothing,
    );
    expect(find.text('→Т'), findsNothing);
  });

  testWidgets('развёрнутая расшифровка — chevron-up и текст размера body', (
    tester,
  ) async {
    AppIosGlass.debugSetSupported(true);
    TranscriptionCache.put(
      '1',
      TranscriptionResult(status: 1, text: 'привет из расшифровки'),
      expanded: true,
    );
    await tester.pumpWidget(_bubble(showMeta: true, audioId: 7, ios: true));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('voice-transcribe-expanded')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('voice-transcribe-collapsed')),
      findsNothing,
    );

    final text = tester.widget<Text>(find.text('привет из расшифровки'));
    expect(text.style?.fontSize, IosBubbleMetrics.textSize);
  });

  testWidgets('тап по →Т разворачивает, повторный сворачивает', (tester) async {
    TranscriptionCache.put(
      '1',
      TranscriptionResult(status: 1, text: 'раз два три'),
    );
    await tester.pumpWidget(_bubble(showMeta: true, audioId: 7));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('voice-transcribe-collapsed')));
    await tester.pumpAndSettle();
    expect(find.text('раз два три'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('voice-transcribe-expanded')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('voice-transcribe-expanded')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('voice-transcribe-collapsed')),
      findsOneWidget,
    );
  });

  testWidgets('с реакциями расшифровка без дубля времени', (tester) async {
    TranscriptionCache.put(
      '1',
      TranscriptionResult(status: 1, text: 'текст'),
      expanded: true,
    );
    await tester.pumpWidget(_bubble(showMeta: false, audioId: 7));
    await tester.pump();
    expect(find.text('текст'), findsOneWidget);
    expect(
      find.text(formatClock(DateTime.fromMillisecondsSinceEpoch(_time))),
      findsNothing,
    );
  });
}
