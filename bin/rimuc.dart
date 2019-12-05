import 'dart:io';
import 'package:rimu/src/rimuc.dart';

/*
  Command-lne app to convert Rimu source to HTML.
  Run 'node rimu.js --help' for details.
*/

// Main wrapper to handle execeptions and set system exit code.
void main(List<String> args) {
  try {
    rimuc(args);
  } catch (e) {
    exit(1);
  }
  exit(0);
}
