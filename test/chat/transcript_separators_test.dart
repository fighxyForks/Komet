import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/chat/message_cluster.dart';

void main() {
  test('разделитель даты ставится на границе суток', () {
    final late = DateTime(2026, 9, 27, 23, 50).millisecondsSinceEpoch;
    final early = DateTime(2026, 9, 28, 0, 1).millisecondsSinceEpoch;
    expect(needsDateSeparator(null, late), isTrue);
    expect(needsDateSeparator(late, late + 60000), isFalse);
    expect(needsDateSeparator(late, early), isTrue);
  });

  test('непрочитанные начинаются со следующего сообщения после метки', () {
    final times = [10, 20, 30];
    expect(firstUnreadIndex(times, null), -1);
    expect(firstUnreadIndex(times, 20), 2);
    expect(firstUnreadIndex(times, 30), -1);
  });
}
