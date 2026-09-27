import 'package:flutter/foundation.dart';

/// Listenables that rebuild the native transcript.
/// Composer height and highlight stay out: height is chrome, highlight is a command.
List<Listenable> nativeTranscriptListenables({
  required Listenable messages,
  required Listenable readTime,
  required Listenable selection,
  required Listenable timestamps,
}) => [messages, readTime, selection, timestamps];
