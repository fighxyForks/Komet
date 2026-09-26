import '../../models/story.dart';

const Duration storyPhotoDuration = Duration(seconds: 5);

/// Индекс, с которого продолжается просмотр владельца.
/// Совпадает с прежним правилом экрана: первое непрочитанное, либо сохранённая
/// позиция, если она строго после него и не на последней истории.
int storyResumeIndex({
  required int readCount,
  required List<int> storyIds,
  int? savedId,
}) {
  final count = storyIds.length;
  if (count == 0) return 0;
  final firstUnread = (readCount > 0 && readCount < count) ? readCount : 0;
  if (savedId == null) return firstUnread;
  final saved = storyIds.indexOf(savedId);
  if (saved <= firstUnread || saved >= count - 1) return firstUnread;
  return saved;
}

String storyTimeLabel(int epochTime, int nowMs) {
  final ms = epochTime < 1000000000000 ? epochTime * 1000 : epochTime;
  final diff = (nowMs - ms) ~/ 1000;
  if (diff < 60) return 'только что';
  if (diff < 3600) return '${diff ~/ 60} мин';
  if (diff < 86400) return '${diff ~/ 3600} ч';
  return '${diff ~/ 86400} дн';
}

Map<String, dynamic> storyReactRequest({
  required StoryOwner owner,
  required int storyId,
  required StoryReaction reaction,
}) {
  return {
    'owner': owner.toMap(),
    'storyId': storyId,
    'reaction': reaction.toMap(),
  };
}
