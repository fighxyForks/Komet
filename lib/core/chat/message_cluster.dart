/// One neighbour in a transcript, enough to decide grouping.
class ClusterNeighbor {
  final int senderId;
  final bool outgoing;
  final int timeMillis;
  final bool control;

  const ClusterNeighbor({
    required this.senderId,
    required this.outgoing,
    required this.timeMillis,
    required this.control,
  });
}

enum MergePolicy { ios, material }

enum ClusterRole { single, top, middle, bottom }

/// The iOS grouping window. Material uses five minutes and ignores the day.
const iosMergeWindow = Duration(minutes: 10);
const materialMergeWindow = Duration(minutes: 5);

bool shouldMerge(
  ClusterNeighbor? previous,
  ClusterNeighbor next,
  MergePolicy policy,
) {
  if (previous == null) return false;
  if (previous.control || next.control) return false;
  if (previous.senderId != next.senderId) return false;
  final gap = next.timeMillis - previous.timeMillis;
  if (gap < 0) return false;
  switch (policy) {
    case MergePolicy.ios:
      if (previous.outgoing != next.outgoing) return false;
      if (gap > iosMergeWindow.inMilliseconds) return false;
      return sameCalendarDay(previous.timeMillis, next.timeMillis);
    case MergePolicy.material:
      return gap < materialMergeWindow.inMilliseconds;
  }
}

ClusterRole clusterRole({
  required ClusterNeighbor? previous,
  required ClusterNeighbor message,
  required ClusterNeighbor? next,
  required MergePolicy policy,
}) {
  if (message.control) return ClusterRole.single;
  final withPrevious = shouldMerge(previous, message, policy);
  final withNext = next != null && shouldMerge(message, next, policy);
  if (!withPrevious && !withNext) return ClusterRole.single;
  if (!withPrevious && withNext) return ClusterRole.top;
  if (withPrevious && !withNext) return ClusterRole.bottom;
  return ClusterRole.middle;
}

/// Sender name on the first bubble of an incoming group cluster.
bool showsSender(ClusterRole role, {required bool incomingGroup}) =>
    incomingGroup && (role == ClusterRole.single || role == ClusterRole.top);

/// Avatar on the last bubble of an incoming group cluster.
bool showsAvatar(ClusterRole role, {required bool incomingGroup}) =>
    incomingGroup &&
    (role == ClusterRole.single || role == ClusterRole.bottom);

/// Material keeps the previous sender-id rule and ignores the time window.
bool materialShowsSender(ClusterNeighbor? previous, ClusterNeighbor message) =>
    previous?.senderId != message.senderId;

bool materialShowsAvatar(ClusterNeighbor message, ClusterNeighbor? next) =>
    next?.senderId != message.senderId;

bool needsDateSeparator(int? previousMillis, int timeMillis) {
  if (previousMillis == null) return true;
  return !sameCalendarDay(previousMillis, timeMillis);
}

int firstUnreadIndex(Iterable<int> times, int? anchorMillis) {
  if (anchorMillis == null) return -1;
  var index = 0;
  for (final time in times) {
    if (time > anchorMillis) return index;
    index++;
  }
  return -1;
}

bool sameCalendarDay(int a, int b) {
  final left = DateTime.fromMillisecondsSinceEpoch(a);
  final right = DateTime.fromMillisecondsSinceEpoch(b);
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
