class StoriesScrollHysteresis {
  static const double pullTriggerPx = 16.0;
  static const double archivePullTriggerPx = 56.0;
  static const double disarmOverscrollAbove = 3.0;
  static const double closeStoriesEnter = 12.0;
  static const double closeStoriesExit = 4.0;
  static const double collapseSearchAt = 132.0;

  static bool shouldCloseStories({
    required bool dockedOpen,
    required double offset,
    required bool closeArmed,
  }) {
    if (!dockedOpen) return false;
    if (closeArmed) return offset > closeStoriesExit;
    return offset > closeStoriesEnter;
  }

  static bool nextCloseArmed({
    required bool dockedOpen,
    required double offset,
    required bool closeArmed,
  }) {
    if (!dockedOpen) return false;
    if (offset > closeStoriesEnter) return true;
    if (offset <= closeStoriesExit) return false;
    return closeArmed;
  }

  static bool shouldClearPullRatio({
    required double offset,
    required double pullRatio,
  }) {
    if (offset < 0) return false;
    return pullRatio > 0;
  }

  static bool shouldNotifyPullClear({
    required double offset,
    required double pullRatio,
    required bool overscrollRevealArmed,
  }) {
    if (offset < 0) return false;
    final disarm = offset > disarmOverscrollAbove && overscrollRevealArmed;
    final clearPull = pullRatio > 0;
    return disarm || clearPull;
  }
}
