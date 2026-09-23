import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/media/video_request_headers.dart';

const _agent = 'SyntheticAgent/1.0 (Android 14)';

Map<String, String> _headers(String url, {String? agent = _agent}) =>
    videoRequestHeaders(Uri.parse(url), sessionUserAgent: agent);

void main() {
  test('ссылки okcdn получают User-Agent сессии', () {
    expect(_headers('https://vd1.okcdn.ru/?expires=1'), {'User-Agent': _agent});
  });

  test('ссылки vkuser.net получают User-Agent сессии', () {
    expect(_headers('https://cdn-1.vkuser.net/video.mp4?expires=1'), {
      'User-Agent': _agent,
    });
  });

  test('любая ссылка с srcAg привязана к клиенту', () {
    expect(_headers('https://media.example.org/v.mp4?srcAg=UNKNOWN_ANDROID'), {
      'User-Agent': _agent,
    });
  });

  test('посторонние хосты не получают User-Agent', () {
    expect(_headers('https://media.example.org/v.mp4'), isEmpty);
    expect(_headers('https://notvkuser.net/v.mp4'), isEmpty);
  });

  test('без User-Agent сессии заголовков нет', () {
    expect(_headers('https://cdn-1.vkuser.net/v.mp4', agent: null), isEmpty);
    expect(_headers('https://cdn-1.vkuser.net/v.mp4', agent: '  '), isEmpty);
  });
}
