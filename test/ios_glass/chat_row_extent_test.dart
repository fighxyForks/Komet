import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/screens/chats/chat/view/ios_chat_row.dart';
import 'package:komet/frontend/screens/chats/chat_list_screen.dart';

void main() {
  test('строки чата 78, разделитель закреплённых 1, за пределами — нет', () {
    double? extent(int index) =>
        ChatListScreen.chatRowExtent(index, itemCount: 5, dividerIndex: 2);
    expect(extent(0), IosChatRow.height);
    expect(extent(2), ChatListScreen.pinnedDividerHeight);
    expect(extent(4), IosChatRow.height);
    expect(extent(5), isNull);
    expect(extent(-1), isNull);
    expect(ChatListScreen.chatRowExtent(2, itemCount: 5), IosChatRow.height);
  });

  testWidgets('фиксированные высоты совпадают с реальной высотой строки', (
    tester,
  ) async {
    const count = 6;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverVariedExtentList(
                itemExtentBuilder: (index, _) => ChatListScreen.chatRowExtent(
                  index,
                  itemCount: count,
                  dividerIndex: 2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => index == 2
                      ? const Divider(
                          height: ChatListScreen.pinnedDividerHeight,
                        )
                      : IosChatRow(
                          key: ValueKey('row_$index'),
                          avatar: const SizedBox(),
                          name: 'Синтетический чат $index',
                          time: '12:00',
                          body: const Text('превью'),
                        ),
                  childCount: count,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('row_0'))).height,
      IosChatRow.height,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('row_3'))).dy,
      IosChatRow.height * 2 + ChatListScreen.pinnedDividerHeight,
    );
  });
}
