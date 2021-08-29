import 'dart:convert';
import 'dart:io';
import 'package:rimu/rimu.dart';
import 'package:rimu/src/options.dart';
import 'package:test/test.dart';

// Helpers.

class RimuTestOptions {
  bool reset;
  int safeMode;
  String htmlReplacement;

  RimuTestOptions({this.reset, this.safeMode, this.htmlReplacement});
}

class TestSpec {
  String unsupported;
  String description;
  String input;
  String expectedOutput;
  String expectedCallback;
  RimuTestOptions options;

  TestSpec.fromJson(dynamic decoded) {
    unsupported = decoded['unsupported'] ?? '';
    description = decoded['description'];
    input = decoded['input'];
    expectedOutput = decoded['expectedOutput'];
    expectedCallback = decoded['expectedCallback'];
    options = RimuTestOptions(
        reset: decoded['options']['reset'],
        safeMode: decoded['options']['safeMode'],
        htmlReplacement: decoded['options']['htmlReplacement']);
  }
}

CallbackFunction catchLint = (message) {
  throw 'unexpected callback: ${message.type}: ${message.text}';
};

void main() {
  test('render', () {
    expect(render('Hello *Rimu*!'), '<p>Hello <em>Rimu</em>!</p>');
  });

  test('jsonTests', () {
    final jsonSource = File('./test/rimu-tests.json').readAsStringSync();
    final decoded = json.decode(jsonSource);
    for (var d in decoded) {
      var spec = TestSpec.fromJson(d);
      var unsupported = spec.unsupported.contains('dart');
      if (unsupported) {
        print('skipped unsupported: ${spec.description}');
        continue;
      }
      print('${spec.description}');
      var renderOptions = RenderOptions();
      renderOptions.safeMode = spec.options.safeMode;
      renderOptions.htmlReplacement = spec.options.htmlReplacement;
      renderOptions.reset = spec.options.reset;
      var msg = ''; // Captured callback message.
      if (spec.expectedCallback.isNotEmpty || unsupported) {
        renderOptions.callback = (message) {
          msg += '${message.type}: ${message.text}\n';
        };
      } else {
        renderOptions.callback =
            catchLint; // Callback should not occur, this will throw an error.
      }
      var result = render(spec.input, renderOptions);
      expect(result, spec.expectedOutput);
      if (spec.expectedCallback != null) {
        expect(msg.trim(), spec.expectedCallback);
      }
    }
  });
}
