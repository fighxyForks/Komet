import '../../models/animoji.dart';

typedef AnimojiListLoader = Future<List<Animoji>> Function();

class EmojiAnimojiSource {
  EmojiAnimojiSource._();

  static AnimojiListLoader? loader;

  static Future<List<Animoji>> load() async {
    final fn = loader;
    if (fn == null) return const [];
    return fn();
  }
}
