const List<String> kContactIndexTitles = [
  'А',
  'Б',
  'В',
  'Г',
  'Д',
  'Е',
  'Ж',
  'З',
  'И',
  'Й',
  'К',
  'Л',
  'М',
  'Н',
  'О',
  'П',
  'Р',
  'С',
  'Т',
  'У',
  'Ф',
  'Х',
  'Ц',
  'Ч',
  'Ш',
  'Щ',
  'Э',
  'Ю',
  'Я',
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
  '#',
];

const String kContactOtherSection = '#';

bool _isCyrillic(int rune) => rune >= 0x0400 && rune <= 0x04FF;

bool _isLatin(int rune) =>
    (rune >= 0x41 && rune <= 0x5A) || (rune >= 0xC0 && rune <= 0x24F);

String contactSectionLetter(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) return kContactOtherSection;
  final letter = String.fromCharCode(trimmed.runes.first).toUpperCase();
  if (letter == 'Ё') return 'Е';
  if (letter.toLowerCase() == letter) return kContactOtherSection;
  return letter;
}

int _scriptRank(String letter) {
  if (letter == kContactOtherSection) return 3;
  final rune = letter.runes.first;
  if (_isCyrillic(rune)) return 0;
  if (_isLatin(rune)) return 1;
  return 2;
}

int compareContactSections(String a, String b) {
  final rank = _scriptRank(a).compareTo(_scriptRank(b));
  if (rank != 0) return rank;
  return a.compareTo(b);
}
