// Basic rendering tests (full syntax tested in rimu_test.dart).

import 'package:test/test.dart';
import 'package:rimu/src/quotes.dart' as quotes;
import 'package:rimu/src/replacements.dart' as replacements;
import 'package:rimu/src/spans.dart';

void main() {
  test('spans', () {
    quotes.init();
    replacements.init();

    var input = 'Hello *Cruel* World!';
    var frags = fragQuote(Fragment(text: input, done: false));
    expect(frags.length, 5);
    var output = defrag(frags);
    expect(output, 'Hello <em>Cruel</em> World!');
    expect(render(input), output);

    input = 'Hello **Cruel** World!';
    frags = fragQuote(Fragment(text: input, done: false));
    expect(frags.length, 5);
    output = defrag(frags);
    expect(output, 'Hello <strong>Cruel</strong> World!');
    expect(render(input), output);

    input = '[Link](http://example.com)';
    frags = fragReplacements([Fragment(text: input, done: false)]);
    expect(frags.length, 3);
    output = defrag(frags);
    expect(output, '<a href=\"http://example.com\">Link</a>');
    expect(render(input), output);

    input = '**[Link](http://example.com)**';
    output = render(input);
    expect(output, '<strong><a href=\"http://example.com\">Link</a></strong>');

    input = '<br>';
    output = render(input);
    expect(output, '<br>');
  });
}
