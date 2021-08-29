import 'package:test/test.dart';
import 'package:rimu/src/quotes.dart';

void main() {
  test('init', () {
    init();
    expect(defs.length, DEFAULT_DEFS.length);
    expect(defs, isNot(same(DEFAULT_DEFS)));
    expect(defs[0], isNot(same(DEFAULT_DEFS[0])));
    expect(defs[0].quote, DEFAULT_DEFS[0].quote);
  });

  test('getDefinition', () {
    init();
    expect(defs.length, DEFAULT_DEFS.length);
    expect(getDefinition('*'), isNotNull);
    expect(getDefinition('X'), isNull);
  });

  test('setDefinition', () {
    init();

    setDefinition(Def(
        quote: '*', openTag: '<strong>', closeTag: '</strong>', spans: true));
    expect(defs.length, DEFAULT_DEFS.length);
    var def = getDefinition('*');
    expect(def.openTag, '<strong>');

    setDefinition(
        Def(quote: 'x', openTag: '<del>', closeTag: '</del>', spans: true));
    expect(defs.length, DEFAULT_DEFS.length + 1);
    def = getDefinition('x');
    expect(def.openTag, '<del>');
    expect(defs.last.openTag, '<del>');

    setDefinition(
        Def(quote: 'xx', openTag: '<u>', closeTag: '</u>', spans: true));
    expect(defs.length, DEFAULT_DEFS.length + 2);
    def = getDefinition('xx');
    expect(def.openTag, '<u>');
    expect(defs.first.openTag, '<u>');
  });

  test('unescape', () {
    init();
    expect(unescape(r'\* \~~ \x'), r'* ~~ \x');
  });
}
