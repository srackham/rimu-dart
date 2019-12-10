import 'package:test/test.dart';
import 'package:rimu/src/lists.dart';
import 'package:rimu/src/api.dart' as api;
import 'package:rimu/src/io.dart' as io;

void main() {
  test('render', () {
    api.init();

    var input = '- Item 1';
    var reader = io.Reader(input);
    var writer = io.Writer();
    render(reader, writer);
    expect(writer.toString(), r'<ul><li>Item 1</li></ul>');

    input = 'Term 1:: Item 1';
    reader = io.Reader(input);
    writer = io.Writer();
    render(reader, writer);
    expect(writer.toString(), r'<dl><dt>Term 1</dt><dd>Item 1</dd></dl>');

    input = r'''- Item 1
""
Quoted
""
- Item 2
 . Nested 1''';
    reader = io.Reader(input);
    writer = io.Writer();
    render(reader, writer);
    expect(writer.toString(),
        r'''<ul><li>Item 1<blockquote><p>Quoted</p></blockquote>
</li><li>Item 2<ol><li>Nested 1</li></ol></li></ul>''');
  });
}
