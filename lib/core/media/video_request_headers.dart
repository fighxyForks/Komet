Map<String, String> videoRequestHeaders(
  Uri uri, {
  required String? sessionUserAgent,
}) {
  if (!_isAgentBound(uri)) return const {};
  final userAgent = sessionUserAgent?.trim();
  if (userAgent == null || userAgent.isEmpty) return const {};
  return {'User-Agent': userAgent};
}

const _agentBoundHosts = ['okcdn.ru', 'vkuser.net'];

bool _isAgentBound(Uri uri) {
  if (uri.queryParameters.containsKey('srcAg')) return true;
  final host = uri.host.toLowerCase();
  return _agentBoundHosts.any(
    (domain) => host == domain || host.endsWith('.$domain'),
  );
}
