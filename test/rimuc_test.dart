import 'dart:convert';
import 'dart:io';

import 'package:rimu/src/rimuc.dart';
import 'package:test/test.dart';

// Helpers.

class TestSpec {
  String unsupported;
  String description;
  String args;
  String input;
  String expectedOutput;
  int exitCode;
  String predicate;
  bool layouts;

  TestSpec.fromJson(dynamic decoded) {
    this.unsupported = decoded['unsupported'] ?? '';
    this.description = decoded['description'];
    this.args = decoded['args'];
    this.input = decoded['input'];
    this.expectedOutput = decoded['expectedOutput'];
    this.exitCode = decoded['exitCode'] ?? 0;
    this.predicate = decoded['predicate'];
    this.layouts = decoded['layouts'] ?? false;
  }
}

// Execute rimuc.dart in command shell.
// args: rimuc command args.
// input: stdin input string.
ProcessResult execRimuc({String args = '', String input = ''}) {
  input = input.replaceAll('\n', r'\n');
  input = input.replaceAll("'", r'\x27');

  // Run rimuc.dart
  // String cmd = "echo -e '$input' | pub run rimuc.dart --no-rimurc $args";

  // Run native rimuc (cuts total testing time from 45s to 16s).
  String cmd = "echo -e '$input' | ./build/rimuc --no-rimurc $args";

  print(cmd);
  return Process.runSync('bash', ['-c', cmd]);
}

void main() {
  test('readResource', () {
    // Throws exception if there is a missing resource file.
    for (var style in ['classic', 'flex', 'plain', 'sequel', 'v8']) {
      readResource('$style-header.rmu');
      readResource('$style-footer.rmu');
    }
    readResource('manpage.txt');
  });

  test('helpCommand', () {
    var result = execRimuc(args: '-h');
    expect(result.exitCode, 0);
    expect(result.stdout.toString().startsWith('\nNAME'), isTrue);
  });

  test('illegalLayout', () {
    var result = execRimuc(args: '--layout foobar');
    expect(result.exitCode, 1);
    expect(result.stderr.toString().startsWith('illegal --layout: foobar'),
        isTrue);
  });

  test('basicRimuc', () {
    expect(() {
      rimuc(['./test/fixtures/hello-rimu.rmu'], testing: true);
    }, returnsNormally);
  });

  // Execute test cases specified in JSON file rimuc-tests.json
  test('jsonTests', () {
    final jsonSource = File('./test/rimuc-tests.json').readAsStringSync();
    final decoded = json.decode(jsonSource);
    for (var d in decoded) {
      var spec = TestSpec.fromJson(d);
      if (spec.unsupported.contains('dart')) {
        continue;
      }
      for (var layout in ['', 'classic', 'flex', 'sequel']) {
        // Skip if not a layouts test and we have a layout, or if it is a layouts test but no layout is specified.
        if (!spec.layouts && layout.isNotEmpty ||
            spec.layouts && layout.isEmpty) {
          continue;
        }
        var args = spec.args.replaceAll('./examples/example-rimurc.rmu',
            './test/fixtures/example-rimurc.rmu');
        if (layout.isNotEmpty) {
          args = '--layout $layout $args';
        }
        var result = execRimuc(args: args, input: spec.input);
        var output = '${result.stdout}${result.stderr}';
        expect(result.exitCode, spec.exitCode);
        switch (spec.predicate) {
          case "equals":
            expect(output, spec.expectedOutput);
            break;
          case "!equals":
            expect(output, isNot(spec.expectedOutput));
            break;
          case "contains":
            expect(output.contains(spec.expectedOutput), isTrue);
            break;
          case "!contains":
            expect(!output.contains(spec.expectedOutput), isTrue);
            break;
          case "startsWith":
            expect(output.startsWith(spec.expectedOutput), isTrue);
            break;
          default:
            throw (spec.description + ': illegal predicate: ' + spec.predicate);
        }
      }
    }
  });
}
