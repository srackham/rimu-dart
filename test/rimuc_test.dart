import 'package:rimu/src/rimuc.dart';
import 'package:test/test.dart';

void main() {
  test('readResource', () {
    // Throws exception if there is a missing resource file.
    for (var style in ['classic', 'flex', 'plain', 'sequel', 'v8']) {
      readResource('$style-header.rmu');
      readResource('$style-footer.rmu');
    }
    readResource('manpage.txt');
  });
}
