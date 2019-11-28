import 'package:test/test.dart';
import 'package:rimu/src/options.dart';

void main() {
  test('init', () {
    init();
    expect(safeMode, 0);
    expect(htmlReplacement, '<mark>replaced HTML</mark>');
    expect(callback, null);
  });

  test('isSafeModeNz', () {
    init();
    expect(isSafeModeNz(), isFalse);
    safeMode = 1;
    expect(isSafeModeNz(), isTrue);
  });

  test('skipMacroDefs', () {
    init();
    expect(skipMacroDefs(), isFalse);
    safeMode = 1;
    expect(skipMacroDefs(), isTrue);
    safeMode = 1 + 8;
    expect(skipMacroDefs(), isFalse);
  });

  test('skipBlockAttributes', () {
    init();
    expect(skipBlockAttributes(), isFalse);
    safeMode = 1;
    expect(skipBlockAttributes(), isFalse);
    safeMode = 1 + 4;
    expect(skipBlockAttributes(), isTrue);
  });

  test('updateOptions', () {
    init();
    updateOptions(RenderOptions(safeMode: 1));
    expect(safeMode, 1);
    expect(htmlReplacement, '<mark>replaced HTML</mark>');
    updateOptions(RenderOptions(htmlReplacement: 'foo'));
    expect(safeMode, 1);
    expect(htmlReplacement, 'foo');
  });

  test('setOption', () {
    init();
    // Illegal values do not update options.
    setOption('safeMode', 'qux');
    expect(safeMode, 0);
    setOption('safeMode', '42');
    expect(safeMode, 0);
    setOption('safeMode', '1');
    setOption('reset', 'qux');
    expect(safeMode, 1);
  });

  test('htmlSafeModeFilter', () {
    init();
    expect(htmlSafeModeFilter('foo'), 'foo');
    safeMode = 1;
    expect(htmlSafeModeFilter('foo'), '');
    safeMode = 2;
    expect(htmlSafeModeFilter('foo'), '<mark>replaced HTML</mark>');
    safeMode = 3;
    expect(htmlSafeModeFilter('<br>'),'&lt;br&gt;');
    safeMode = 0 + 4;
    expect(htmlSafeModeFilter('foo'), 'foo');
  });
}
