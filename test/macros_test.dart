import 'package:test/test.dart';
import 'package:rimu/src/macros.dart';
import 'package:rimu/src/options.dart' as options;

void main() {
  test('parse', () {
    init();
    options.init();
    expect(defs.length, 2);
    setValue('x', '1', '"');
    expect(defs.length, 3);
    expect(getValue('x'), '1');
    expect(getValue('y'), null);
    expect(render(r'\{x} = {x}'), '{x} = 1');
    expect(render(r'{--=} foobar'), ' foobar');
    expect(render(r'{--!} foobar'), '');
    setValue('x?', '2', '"');
    expect(getValue('x'), '1');
    setValue('y', r'$1 $2', '"');
    expect(render(r'{y|foo|bar}'), 'foo bar');
  });
}
