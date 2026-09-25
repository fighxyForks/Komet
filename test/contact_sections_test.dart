import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/contacts/contact_sections.dart';

void main() {
  test('буква секции — первая буква имени в верхнем регистре', () {
    expect(contactSectionLetter('анна'), 'А');
    expect(contactSectionLetter('  Борис'), 'Б');
    expect(contactSectionLetter('anna'), 'A');
  });

  test('Ё попадает в секцию Е', () {
    expect(contactSectionLetter('Ёжик'), 'Е');
  });

  test('цифры, эмодзи и пустые имена — в секцию #', () {
    expect(contactSectionLetter('8 800'), '#');
    expect(contactSectionLetter('🙂 друг'), '#');
    expect(contactSectionLetter('   '), '#');
  });

  test('кириллица идёт перед латиницей, # — последней', () {
    final letters = ['#', 'B', 'Я', 'A', 'А', 'Б']
      ..sort(compareContactSections);
    expect(letters, ['А', 'Б', 'Я', 'A', 'B', '#']);
  });

  test('латинская A и кириллическая А — разные секции в своих алфавитах', () {
    expect(contactSectionLetter('Anna'), isNot(contactSectionLetter('Анна')));
    expect(compareContactSections('А', 'A'), lessThan(0));
  });

  test('указатель: полный алфавит, кириллица, латиница и #', () {
    expect(kContactIndexTitles.first, 'А');
    expect(
      kContactIndexTitles.indexOf('Я'),
      lessThan(kContactIndexTitles.indexOf('A')),
    );
    expect(kContactIndexTitles.last, '#');
    expect(kContactIndexTitles.length, 29 + 26 + 1);
  });
}
