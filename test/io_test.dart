import 'package:test/test.dart';
import 'package:rimu/src/io.dart';

void main() {
  test('Reader', () {
    var reader = Reader('');
    expect(reader.eof(), false);
    expect(reader.lines.length, 1);
    expect(reader.cursor, '');
    reader.next();
    expect(reader.eof(), true);

    reader = Reader('Hello\nWorld!');
    expect(reader.lines.length, 2);
    expect(reader.cursor, 'Hello');
    reader.next();
    expect(reader.cursor, 'World!');
    expect(reader.eof(), false);
    reader.next();
    expect(reader.eof(), true);

    reader = Reader('\n\nHello');
    expect(reader.lines.length, 3);
    reader.skipBlankLines();
    expect(reader.cursor, 'Hello');
    expect(reader.eof(), false);
    reader.next();
    expect(reader.eof(), true);

    reader = Reader('Hello\n*\nWorld!\nHello\n< Goodbye >');
    expect(reader.lines.length, 5);
    var lines = reader.readTo(RegExp(r'\*'));
    expect(lines.length, 1);
    expect(lines[0], 'Hello');
    expect(reader.eof(), false);
    lines = reader.readTo(RegExp(r'^<(.*)>$'));
    expect(lines.length, 3);
    expect(lines[2], ' Goodbye ');
    expect(reader.eof(), true);

    reader = Reader('\n\nHello\nWorld!');
    expect(reader.lines.length, 4);
    reader.skipBlankLines();
    lines = reader.readTo(RegExp(r'^$'));
    expect(lines.length, 2);
    expect(lines[1], 'World!');
    expect(reader.eof(), true);
  });

  test('Writer', () {
    var writer = Writer();
    writer.write('Hello');
    expect(writer.buffer[0], 'Hello');
    writer.write('World!');
    expect(writer.buffer[1], 'World!');
    expect(writer.toString(), 'HelloWorld!');
  });
}
