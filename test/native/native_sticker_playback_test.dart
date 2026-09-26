import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/native/native_sticker_playback.dart';

void main() {
  test('анимируются первые два видимых стикера', () {
    final plays = nativeStickerPlays(const [
      NativeStickerPlay(id: 'a', lottieUrl: null),
      NativeStickerPlay(id: 'b', lottieUrl: ''),
      NativeStickerPlay(id: 'c', lottieUrl: 'https://cdn/c.json'),
      NativeStickerPlay(id: 'd', lottieUrl: 'https://cdn/d.json'),
      NativeStickerPlay(id: 'e', lottieUrl: 'https://cdn/e.json'),
    ]);
    expect(plays.keys.toList(), ['c', 'd']);
    expect(plays['c'], 'https://cdn/c.json');
  });
}
