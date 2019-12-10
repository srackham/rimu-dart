import 'package:test/test.dart';
import 'package:rimu/src/lineblocks.dart';
import 'package:rimu/src/io.dart' as io;
import 'package:rimu/src/blockattributes.dart' as blockattributes;
import 'package:rimu/src/delimitedblocks.dart' as delimitedblocks;
import 'package:rimu/src/options.dart' as options;
import 'package:rimu/src/quotes.dart' as quotes;
import 'package:rimu/src/replacements.dart' as replacements;

void main() {
  test('render', () {
    Map<String, String> tests = {
      r'# foo': r'<h1>foo</h1>',
      r'// foo': r'',
      r'<image:foo|bar>': r'<img src="foo" alt="bar">',
      r'<<#foo>>': r'<div id="foo"></div>',
      r'.class #id "css"': r'',
      r".safeMode='0'": r'',
      r"|code|='<code>|</code>'": r'',
      r"^='<sup>|</sup>'": r'',
      r"/\.{3}/i = '&hellip;'": r'',
      r"{foo}='bar'": r'',
    };
    // TODO: replace with api.init()
    blockattributes.init();
    delimitedblocks.init();
    options.init();
    quotes.init();
    replacements.init();
    tests.forEach((k, v) {
      var reader = io.Reader(k);
      var writer = io.Writer();
      render(reader, writer);
      var got = writer.toString();
      expect(got, v);
    });
  });
}
