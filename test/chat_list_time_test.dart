import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:komet/core/utils/chat_list_time.dart';

const _ru = ChatListTimeLabels(
  locale: 'ru',
  yesterday: 'Вчера',
  datePattern: 'dd.MM.yy',
);
const _en = ChatListTimeLabels(
  locale: 'en',
  yesterday: 'Yesterday',
  datePattern: 'M/d/yy',
);

String _ruAt(DateTime time, DateTime now) =>
    formatChatListTime(time, now: now, labels: _ru);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
    await initializeDateFormatting('en');
  });

  final now = DateTime(2026, 9, 24, 10, 30);

  group('виды подписи', () {
    test('сегодня — время, в том числе в первую минуту суток', () {
      expect(_ruAt(DateTime(2026, 9, 24, 0, 0), now), '00:00');
      expect(_ruAt(DateTime(2026, 9, 24, 9, 5), now), '09:05');
    });

    test('время из будущего при сбитых часах — тоже время', () {
      expect(_ruAt(DateTime(2026, 9, 24, 23, 50), now), '23:50');
      expect(
        chatListTimeKind(DateTime(2026, 9, 25, 1), now),
        ChatListTimeKind.time,
      );
    });

    test('вчера считается по календарю, а не по 24 часам', () {
      final justAfterMidnight = DateTime(2026, 9, 24, 0, 5);
      expect(_ruAt(DateTime(2026, 9, 23, 23, 55), justAfterMidnight), 'Вчера');
      expect(_ruAt(DateTime(2026, 9, 23, 0, 1), now), 'Вчера');
    });

    test('от двух до шести дней — день недели', () {
      expect(_ruAt(DateTime(2026, 9, 22, 12), now), 'вт');
      expect(_ruAt(DateTime(2026, 9, 18, 12), now), 'пт');
      expect(
        formatChatListTime(DateTime(2026, 9, 21, 12), now: now, labels: _en),
        'Mon',
      );
    });

    test('неделя и старше в этом году — число и месяц', () {
      expect(
        chatListTimeKind(DateTime(2026, 9, 17, 12), now),
        ChatListTimeKind.dayMonth,
      );
      expect(_ruAt(DateTime(2026, 3, 12, 12), now), '12 мар.');
      expect(
        formatChatListTime(DateTime(2026, 3, 12, 12), now: now, labels: _en),
        'Mar 12',
      );
    });

    test('прошлые годы — короткая дата', () {
      expect(_ruAt(DateTime(2025, 3, 12, 12), now), '12.03.25');
      expect(
        formatChatListTime(DateTime(2025, 3, 12, 12), now: now, labels: _en),
        '3/12/25',
      );
    });
  });

  group('границы', () {
    test('через Новый год вчера и дни недели остаются относительными', () {
      final newYear = DateTime(2027, 1, 2, 9);
      expect(_ruAt(DateTime(2027, 1, 1, 22), newYear), 'Вчера');
      expect(
        chatListTimeKind(DateTime(2026, 12, 30, 12), newYear),
        ChatListTimeKind.weekday,
      );
      expect(_ruAt(DateTime(2026, 12, 20, 12), newYear), '20.12.26');
    });

    test('вчера на стыке месяцев', () {
      expect(
        _ruAt(DateTime(2026, 2, 28, 23), DateTime(2026, 3, 1, 8)),
        'Вчера',
      );
    });

    test('до полуночи считается от текущего момента', () {
      expect(
        untilNextMidnight(DateTime(2026, 9, 24, 23, 59, 30)),
        const Duration(seconds: 30),
      );
      expect(
        untilNextMidnight(DateTime(2026, 12, 31, 12)),
        const Duration(hours: 12),
      );
    });
  });
}
