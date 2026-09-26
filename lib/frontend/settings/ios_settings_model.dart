class IosSettingsEntry {
  final String id;
  final String title;
  final String section;
  final List<String> keywords;

  const IosSettingsEntry({
    required this.id,
    required this.title,
    this.section = '',
    this.keywords = const [],
  });
}

class IosSettingsHit {
  final IosSettingsEntry entry;

  const IosSettingsHit(this.entry);
}

List<IosSettingsHit> filterIosSettings(
  List<IosSettingsEntry> entries,
  String query,
) {
  final needle = query.trim().toLowerCase().replaceAll('ё', 'е');
  if (needle.isEmpty) return const [];
  return [
    for (final entry in entries)
      if (_matches(entry, needle)) IosSettingsHit(entry),
  ];
}

bool _matches(IosSettingsEntry entry, String needle) {
  final haystack = [
    entry.title,
    entry.section,
    ...entry.keywords,
  ].join(' ').toLowerCase().replaceAll('ё', 'е');
  return haystack.contains(needle);
}
