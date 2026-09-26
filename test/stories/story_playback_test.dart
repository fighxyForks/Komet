import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/stories/story_playback.dart';
import 'package:komet/models/story.dart';

void main() {
  test('продолжение с первого непрочитанного или сохранённой позиции', () {
    expect(storyResumeIndex(readCount: 0, storyIds: [1, 2, 3]), 0);
    expect(
      storyResumeIndex(readCount: 0, storyIds: [1, 2, 3], savedId: 2),
      1,
    );
    expect(
      storyResumeIndex(readCount: 0, storyIds: [1, 2, 3], savedId: 3),
      0,
    );
    expect(storyResumeIndex(readCount: 2, storyIds: [1, 2, 3, 4, 5]), 2);
    expect(
      storyResumeIndex(readCount: 1, storyIds: [1, 2, 3, 4], savedId: 3),
      2,
    );
    expect(
      storyResumeIndex(readCount: 1, storyIds: [1, 2, 3, 4], savedId: 4),
      1,
    );
    expect(
      storyResumeIndex(readCount: 2, storyIds: [1, 2, 3, 4], savedId: 2),
      2,
    );
    expect(storyResumeIndex(readCount: 3, storyIds: const []), 0);
  });

  test('подпись времени и запрос реакции', () {
    const now = 1_700_000_000_000;
    expect(storyTimeLabel(now - 10_000, now), 'только что');
    expect(storyTimeLabel((now ~/ 1000) - 120, now), '2 мин');
    expect(storyTimeLabel(now - 3 * 3600 * 1000, now), '3 ч');
    expect(storyTimeLabel(now - 2 * 86400 * 1000, now), '2 дн');

    const owner = StoryOwner(ownerId: 7);
    final request = storyReactRequest(
      owner: owner,
      storyId: 9,
      reaction: const StoryReaction(id: '❤️'),
    );
    expect(request['storyId'], 9);
    expect(request['owner'], {'ownerId': 7, 'type': 0});
    expect(request['reaction'], {'reactionType': 0, 'id': '❤️'});
  });
}
