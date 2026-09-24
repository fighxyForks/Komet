import 'dart:async';

import 'package:flutter/foundation.dart';

class MessageHighlighter {
  MessageHighlighter({required this.isMounted});

  static const int flashCount = 3;
  static const Duration flashPhase = Duration(milliseconds: 260);

  final bool Function() isMounted;
  final ValueNotifier<String?> id = ValueNotifier(null);
  Timer? _timer;

  void hold(String messageId, Duration duration) {
    _timer?.cancel();
    id.value = messageId;
    _timer = Timer(duration, () => _clear(messageId));
  }

  void flash(String messageId) {
    _timer?.cancel();
    id.value = messageId;
    var phase = 0;
    _timer = Timer.periodic(flashPhase, (timer) {
      if (!isMounted()) {
        timer.cancel();
        return;
      }
      phase++;
      if (phase >= flashCount * 2) {
        timer.cancel();
        _clear(messageId);
        return;
      }
      id.value = phase.isEven ? messageId : null;
    });
  }

  void _clear(String messageId) {
    if (!isMounted()) return;
    if (id.value == messageId) id.value = null;
  }

  void dispose() {
    _timer?.cancel();
    id.dispose();
  }
}
