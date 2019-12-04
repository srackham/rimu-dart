import 'dart:io';
import 'package:rimu/src/rimuc.dart';
import 'package:test/test.dart';

// Helpers.

// Execute rimuc.dart in command shell.
// args: rimuc command args.
// input: stdin input string.
ProcessResult execRimuc({String args = '', String input = ''}) {
  input = input.replaceAll('\n', r'\n');
  input = input.replaceAll('"', r'\x22');
  input = input.replaceAll('`', r'\x60');
  return Process.runSync('sh', [
    '-c',
    'echo -e "' + input + '" | pub run rimuc.dart --no-rimurc ' + args
  ]);
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
}
