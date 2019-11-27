import 'package:rimu/rimu.dart' as rimu;
import 'package:test/test.dart';

void main() {
  test('render', () {
    expect(
        rimu.render('Hello *Rimu*!'), '<p>Hello <em>Rimu</em>!</p>\n');
  });
}
