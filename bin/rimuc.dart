import 'dart:io';
import 'package:rimu/rimu.dart';
import './resources.dart';

// Helpers.
die(String message) {
  stderr.writeln(message);
  exit(1);
}

String readResourceFile(String name) {
  if (!resources.containsKey(name)) {
    die('missing resource: ${name}');
  }
  return resources[name];
}

main(List<String> arguments) async {
  print(render('Hello *Rimu*!',
      RenderOptions(reset: true, callback: (CallbackMessage message) {})));
  print(readResourceFile('plain-footer.rmu'));
}
