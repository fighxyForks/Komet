import 'package:flutter_test/flutter_test.dart';
import 'package:komet/backend/modules/chats.dart';

void main() {
  test('moves pinned chats to the order dropped in the list', () {
    expect(ChatsModule.pinnedOrder([1, 2, 3], [3, 1, 2]), [3, 1, 2]);
  });

  test('keeps pinned chats of other folders in their slots', () {
    expect(ChatsModule.pinnedOrder([1, 2, 3, 4], [4, 2]), [1, 4, 3, 2]);
  });

  test('ignores chats that are not pinned', () {
    expect(ChatsModule.pinnedOrder([1, 2], [9, 2, 1]), [2, 1]);
  });
}
