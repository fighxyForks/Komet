import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/chat/message_cluster.dart';
import 'package:komet/frontend/widgets/attachment/bubbles/bubble_context.dart';

ClusterNeighbor _n({
  int sender = 1,
  bool outgoing = false,
  required int time,
  bool control = false,
}) => ClusterNeighbor(
  senderId: sender,
  outgoing: outgoing,
  timeMillis: time,
  control: control,
);

BubbleShape _shape(ClusterRole role) => switch (role) {
  ClusterRole.single => BubbleShape.singleMiddle,
  ClusterRole.top => BubbleShape.singleTop,
  ClusterRole.bottom => BubbleShape.singleBottom,
  ClusterRole.middle => BubbleShape.groupedMiddle,
};

void main() {
  final noon = DateTime(2026, 9, 27, 12).millisecondsSinceEpoch;

  ClusterRole roleOf({
    ClusterNeighbor? previous,
    required ClusterNeighbor message,
    ClusterNeighbor? next,
    required MergePolicy policy,
  }) => clusterRole(
    previous: previous,
    message: message,
    next: next,
    policy: policy,
  );

  test('материал сохраняет текущие формы пузыря', () {
    final message = _n(time: noon);
    expect(
      _shape(roleOf(message: message, policy: MergePolicy.material)),
      BubbleShape.singleMiddle,
    );
    expect(
      _shape(
        roleOf(
          message: message,
          next: _n(time: noon + 60000),
          policy: MergePolicy.material,
        ),
      ),
      BubbleShape.singleTop,
    );
    expect(
      _shape(
        roleOf(
          previous: _n(time: noon - 60000),
          message: message,
          policy: MergePolicy.material,
        ),
      ),
      BubbleShape.singleBottom,
    );
    expect(
      _shape(
        roleOf(
          previous: _n(time: noon - 60000),
          message: message,
          next: _n(time: noon + 60000),
          policy: MergePolicy.material,
        ),
      ),
      BubbleShape.groupedMiddle,
    );
    expect(
      materialShowsSender(null, message),
      isTrue,
    );
    expect(
      materialShowsSender(_n(sender: 1, time: noon), message),
      isFalse,
    );
    expect(
      materialShowsAvatar(message, _n(sender: 2, time: noon)),
      isTrue,
    );
  });

  for (final policy in MergePolicy.values) {
    final window = policy == MergePolicy.ios
        ? iosMergeWindow.inMilliseconds
        : materialMergeWindow.inMilliseconds;

    test('границы окна для $policy', () {
      final message = _n(time: noon, outgoing: false);
      final below = _n(time: noon - (window - 1), outgoing: false);
      final exact = _n(time: noon - window, outgoing: false);
      final above = _n(time: noon - window - 1, outgoing: false);
      expect(shouldMerge(below, message, policy), isTrue);
      expect(
        shouldMerge(exact, message, policy),
        policy == MergePolicy.ios,
      );
      expect(shouldMerge(above, message, policy), isFalse);
    });
  }

  test('ios не склеивает смену автора, исходящего, дня и служебное', () {
    final message = _n(time: noon);
    expect(shouldMerge(_n(sender: 2, time: noon - 1000), message, MergePolicy.ios), isFalse);
    expect(
      shouldMerge(
        _n(time: noon - 1000, outgoing: true),
        message,
        MergePolicy.ios,
      ),
      isFalse,
    );
    final nextDay = DateTime(2026, 9, 28, 0, 1).millisecondsSinceEpoch;
    final late = DateTime(2026, 9, 27, 23, 59).millisecondsSinceEpoch;
    expect(
      shouldMerge(_n(time: late), _n(time: nextDay), MergePolicy.ios),
      isFalse,
    );
    expect(
      shouldMerge(_n(time: noon, control: true), message, MergePolicy.ios),
      isFalse,
    );
    expect(
      clusterRole(
        previous: null,
        message: message,
        next: null,
        policy: MergePolicy.ios,
      ),
      ClusterRole.single,
    );
  });

  test('временные id не влияют на склейку', () {
    final previous = _n(time: noon);
    final next = _n(time: noon + 1000);
    expect(shouldMerge(previous, next, MergePolicy.ios), isTrue);
    expect(showsSender(ClusterRole.top, incomingGroup: true), isTrue);
    expect(showsAvatar(ClusterRole.top, incomingGroup: true), isFalse);
    expect(showsAvatar(ClusterRole.bottom, incomingGroup: true), isTrue);
    expect(showsSender(ClusterRole.single, incomingGroup: false), isFalse);
  });
}
