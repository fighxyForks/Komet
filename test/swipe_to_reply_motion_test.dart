import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/motion/ios_motion.dart';
import 'package:komet/frontend/screens/chats/chat/view/message_row_widgets.dart';

void main() {
  test('reply triggers differ for incoming vs outgoing', () {
    expect(IosMotion.replyTriggerIncoming, 48);
    expect(IosMotion.replyTriggerOutgoing, 60);
    expect(
      IosMotion.replyTriggerOutgoing,
      greaterThan(IosMotion.replyTriggerIncoming),
    );
  });

  testWidgets('swipe past trigger invokes onReply', (tester) async {
    var replied = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeToReply(
            isMe: false,
            onReply: () => replied = true,
            child: const SizedBox(
              width: 300,
              height: 60,
              child: ColoredBox(color: Colors.blue),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final center = tester.getCenter(find.byType(SwipeToReply));
    // Drag left past incoming trigger (48).
    final gesture = await tester.startGesture(center);
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(-8, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(replied, isTrue);
  });
}
