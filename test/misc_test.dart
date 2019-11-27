// @Skip('Skip this test file')

import 'package:test/test.dart';

void main() {
  test('default nulls', () {
    var v;
    expect(v,  null);
    int n;
    expect(n,  null);
    Map m;
    expect(m,  null);
  });
}
