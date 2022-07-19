import 'dart:io';

import 'package:rimu/src/rimuc.dart';

/*
  Command-lne app to convert Rimu source to HTML.
*/

// Main wrapper to handle execeptions and set system exit code.
void main(List<String> args) {
  try {
    rimuc(args);
  } catch (e) {
    if (e is! String) {
      stderr.writeln('unexpected error: $e');
    }
    exit(1);
  }
  exit(0);
}
