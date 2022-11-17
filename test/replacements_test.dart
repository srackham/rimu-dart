import 'package:test/test.dart';
import 'package:rimu/src/replacements.dart';

void main() {
  test('init', () {
    init();
    expect(defs!.length, DEFAULT_DEFS.length);
    expect(defs, isNot(same(DEFAULT_DEFS)));
    expect(defs![0], isNot(same(DEFAULT_DEFS[0])));
    expect(defs![0].replacement, DEFAULT_DEFS[0].replacement);
  });

  test('getDefinition', () {
    init();
    expect(defs!.length, DEFAULT_DEFS.length);
    expect(getDefinition(r'\\?<image:([^\s|]+?)>'), isNotNull);
    expect(getDefinition(r'X'), isNull);
  });

  test('setDefinition', () {
    init();
    setDefinition(r'\\?<image:([^\s|]+?)>', '', 'foo');
    expect(defs!.length, DEFAULT_DEFS.length);
    var def = getDefinition(r'\\?<image:([^\s|]+?)>')!;
    expect(def.replacement, 'foo');
    expect(def.match!.isCaseSensitive, true);
    expect(def.match!.isMultiLine, false);
    setDefinition(r'bar', 'mi', 'foo');
    expect(defs!.length, DEFAULT_DEFS.length + 1);
    def = defs!.last;
    expect(def.match!.pattern, 'bar');
    expect(def.replacement, 'foo');
    expect(def.match!.isCaseSensitive, false);
    expect(def.match!.isMultiLine, true);
  });
}
