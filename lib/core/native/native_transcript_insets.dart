class NativeTranscriptInsets {
  final double top;
  final double bottom;

  const NativeTranscriptInsets({required this.top, required this.bottom});

  static const double composerGap = 8;

  static NativeTranscriptInsets compute({
    required bool underlap,
    required double statusBar,
    required double header,
    required double pinned,
    required double callBanner,
    required double composer,
    required double panels,
    double gap = composerGap,
  }) {
    final top = underlap ? statusBar + header + pinned + callBanner : 0.0;
    return NativeTranscriptInsets(top: top, bottom: composer + panels + gap);
  }
}
