// Basic rendering tests (full syntax tested in rimu_test.dart).

import 'package:test/test.dart';
import 'package:rimu/src/blockattributes.dart';
import 'package:rimu/src/options.dart' as options;

void main() {
  test('parse', () {
    options.init();
    init();
    var success = parse('.foo bar #id "font-size: 16px;" [title="Hello!"]');
    expect(success, isTrue);
    expect(classes, 'foo bar');
    expect(id, 'id');
    expect(css, 'font-size: 16px;');
    expect(attributes, 'title="Hello!"');
  });

  test('injectHtmlAttributes', () {
    init();
    classes = 'foo bar';
    id = 'ID';
    css = 'font-size: 16px;';
    attributes = 'title="Hello!"';
    var result = injectHtmlAttributes('<p class="do">');
    expect(result,
        '<p id="id" style="font-size: 16px;" title="Hello!" class="foo bar do">');
    expect(classes, '');
    expect(css, '');
    expect(attributes, '');
  });
}
