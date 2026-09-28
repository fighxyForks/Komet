import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/utils/channel_comments.dart';

void main() {
  group('showsCommentsButton', () {
    test('channel with comments on shows the button', () {
      expect(
        showsCommentsButton(isChannelPost: true, chatOptions: {'COMMENTS'}),
        isTrue,
      );
    });

    test('channel with comments reported off hides the button', () {
      expect(
        showsCommentsButton(
          isChannelPost: true,
          chatOptions: {kCommentsOffOption, 'SIGN_ADMIN'},
        ),
        isFalse,
      );
    });

    test('missing data keeps the button', () {
      expect(
        showsCommentsButton(isChannelPost: true, chatOptions: const {}),
        isTrue,
      );
      expect(
        showsCommentsButton(isChannelPost: true, chatOptions: {'OFFICIAL'}),
        isTrue,
      );
    });

    test('not a channel post never shows the button', () {
      expect(
        showsCommentsButton(isChannelPost: false, chatOptions: {'COMMENTS'}),
        isFalse,
      );
    });
  });

  group('withCommentsMarker', () {
    test('marks an explicit false', () {
      expect(
        withCommentsMarker({'OFFICIAL'}, {'OFFICIAL': true, 'COMMENTS': false}),
        {'OFFICIAL', kCommentsOffOption},
      );
    });

    test('leaves true and missing values alone', () {
      expect(withCommentsMarker({'COMMENTS'}, {'COMMENTS': true}), {
        'COMMENTS',
      });
      expect(withCommentsMarker(const {}, const {}), isEmpty);
    });
  });
}
