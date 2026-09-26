import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../core/media/tlottie/tlottie.dart';

class NativeStickerPlay {
  final String id;
  final String? lottieUrl;

  const NativeStickerPlay({required this.id, required this.lottieUrl});
}

/// Первые [limit] стикеров с непустой анимацией, в порядке видимости.
Map<String, String> nativeStickerPlays(
  Iterable<NativeStickerPlay> rows, {
  int limit = 2,
}) {
  final plays = <String, String>{};
  for (final row in rows) {
    final url = row.lottieUrl;
    if (url == null || url.isEmpty) continue;
    plays[row.id] = url;
    if (plays.length >= limit) break;
  }
  return plays;
}

class NativeStickerPlayback {
  NativeStickerPlayback({required this.onFrame});

  final void Function(String id, Uint8List rgba, int width, int height) onFrame;

  static const _px = 160;
  static const _max = 2;

  final Map<String, _StickerSlot> _slots = {};
  Timer? _timer;
  Timer? _debounce;
  Map<String, String> _pending = const {};
  bool _busy = false;
  bool _disposed = false;

  void setVisible(Map<String, String> plays) {
    final limited = nativeStickerPlays(
      [for (final entry in plays.entries) NativeStickerPlay(id: entry.key, lottieUrl: entry.value)],
      limit: _max,
    );
    _pending = limited;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), _apply);
  }

  void _apply() {
    if (_disposed) return;
    final next = _pending;
    final stale = _slots.keys.where((id) => next[id] != _slots[id]?.url).toList();
    for (final id in stale) {
      _slots.remove(id)?.release();
    }
    for (final entry in next.entries) {
      _slots.putIfAbsent(entry.key, () => _StickerSlot(entry.key, entry.value)..start(_px));
    }
    if (_slots.isEmpty) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(const Duration(milliseconds: 80), (_) {
      unawaited(_tick());
    });
  }

  Future<void> _tick() async {
    if (_busy || _disposed) return;
    _busy = true;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final slot in _slots.values.toList()) {
        final clip = slot.clip;
        if (clip == null || clip.frameCount <= 1 || clip.ready.value <= 0) continue;
        final period = clip.durationMs;
        if (period <= 0 || clip.frameCount <= 1) continue;
        final elapsed = now - slot.startedMs;
        final index = ((elapsed % period) / period * (clip.frameCount - 1))
            .round()
            .clamp(0, clip.frameCount - 1);
        if (index == slot.shown || index >= clip.ready.value) continue;
        final image = clip.frameAt(index);
        if (image == null) continue;
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (_disposed || data == null || slot.released) continue;
        slot.shown = index;
        onFrame(
          slot.id,
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          image.width,
          image.height,
        );
      }
    } finally {
      _busy = false;
    }
  }

  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _timer?.cancel();
    for (final slot in _slots.values) {
      slot.release();
    }
    _slots.clear();
  }
}

class _StickerSlot {
  _StickerSlot(this.id, this.url);

  final String id;
  final String url;
  TlottieClip? clip;
  int startedMs = 0;
  int shown = -1;
  bool released = false;

  void start(int px) {
    startedMs = DateTime.now().millisecondsSinceEpoch;
    TlottieEngine.instance.acquire(url, px).then((clip) {
      if (released) {
        if (clip != null) TlottieEngine.instance.release(clip);
        return;
      }
      this.clip = clip;
    });
  }

  void release() {
    released = true;
    final clip = this.clip;
    this.clip = null;
    if (clip != null) TlottieEngine.instance.release(clip);
  }
}
