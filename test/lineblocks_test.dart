import 'package:rimu/src/document.dart' as document;
import 'package:rimu/src/io.dart' as io;
import 'package:rimu/src/lineblocks.dart';
import 'package:test/test.dart';

void main() {
  test('render', () {
    var tests = <String, String>{
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
    document.init();
    tests.forEach((k, v) {
      var reader = io.Reader(k);
      var writer = io.Writer();
      render(reader, writer);
      var got = writer.toString();
      expect(got, v);
    });
  });
}
