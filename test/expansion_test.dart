// Basic rendering tests (full syntax tested in rimu_test.dart).

import 'package:test/test.dart';
import 'package:rimu/src/expansion.dart';

void main() {
  test('expasionOptions', () {
    var opts = ExpansionOptions(macros: true, specials: false);
    opts.merge(ExpansionOptions(macros: false, container: true));
    expect(
        opts,
        ExpansionOptions(
            macros: false,
            container: true,
            skip: null,
            spans: null,
            specials: false));

    opts = ExpansionOptions(macros: true, specials: false);
    opts.parse('-macros +spans');
    expect(
        opts,
        ExpansionOptions(
            macros: false,
            container: null,
            skip: null,
            spans: true,
            specials: false));
  });
}
