import 'package:test/test.dart';
import 'package:rimu/src/delimitedblocks.dart';
import 'package:rimu/src/io.dart' as io;
import 'package:rimu/src/blockattributes.dart' as blockattributes;
import 'package:rimu/src/quotes.dart' as quotes;
import 'package:rimu/src/replacements.dart' as replacements;

void main() {
  test('getDefinition', () {
    init();
    Def? def = getDefinition('paragraph')!;
    expect(def.openTag, '<p>');
    def = getDefinition('foo');
    expect(def, null);
  });

  test('setDefinition', () {
    init();
    setDefinition('indented', '<foo>|</foo>');
    var def = getDefinition('indented')!;
    expect(def.openTag, '<foo>');
    expect(def.closeTag, '</foo>');
  });

  test('render', () {
    blockattributes.init();
    quotes.init();
    replacements.init();
    init();
    var input = 'Test';
    var reader = io.Reader(input);
    var writer = io.Writer();

    render(reader, writer);
    expect(writer.toString(), '<p>Test</p>');

    input = '  Indented';
    reader = io.Reader(input);
    writer = io.Writer();
    render(reader, writer);
    expect(writer.toString(), '<pre><code>Indented</code></pre>');
  });
}
