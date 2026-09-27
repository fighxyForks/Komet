import 'chat_content_unit.dart';

/// FNV-1a 64-bit over a canonical string. Stable across processes.
String layoutRevision(String canonical) {
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = (BigInt.one << 64) - BigInt.one;
  for (final unit in canonical.codeUnits) {
    hash = ((hash ^ BigInt.from(unit)) * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

String layoutRevisionFor({
  required String messageId,
  required String text,
  required List<ChatContentUnit> units,
  required String clusterRole,
  required bool showSender,
  required bool showAvatar,
  required String reply,
  required String forward,
  required String keyboard,
  required String poll,
  required String transcript,
  required bool transcriptOpen,
  required String comments,
  required String meta,
}) {
  final canonical = [
    messageId,
    text,
    units.map((unit) => '${unit.kind}:${_canon(unit.fields)}').join(';'),
    clusterRole,
    showSender ? '1' : '0',
    showAvatar ? '1' : '0',
    reply,
    forward,
    keyboard,
    poll,
    transcriptOpen ? '1' : '0',
    transcript,
    comments,
    meta,
  ].join('\u001f');
  return layoutRevision(canonical);
}

String _canon(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return '{${keys.map((key) => '$key:${_canon(value[key])}').join(',')}}';
  }
  if (value is List) return '[${value.map(_canon).join(',')}]';
  return '$value';
}
