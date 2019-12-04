import 'dart:io';
import 'package:rimu/rimu.dart';
import 'package:path/path.dart' as path;
import 'resources.dart';

/*
  rimuc app implementation.
*/

const VERSION = '11.1.4';
const STDIN = '/dev/stdin';
String HOME_DIR =
    Platform.environment[Platform.isWindows ? 'UserProfile' : 'HOME'];
String RIMURC = path.join(HOME_DIR, '.rimurc');

// Helpers.
die([String message]) {
  if (message != null) {
    stderr.writeln(message);
  }
  throw message;
}

String readResource(String name) {
  if (!resources.containsKey(name)) {
    die('missing resource: ${name}');
  }
  return resources[name];
}

String importLayoutFile(String name) {
  // External layouts not supported in go-rimu.
  die("missing --layout: " + name);
  return '';
}

// Application body.
rimuc(List<String> args) {
  const RESOURCE_TAG = 'resource:'; // Tag for resource files.
  const PREPEND = '--prepend options';
  const STDIN = '-';

  // Command option values.
  int safe_mode = 0;
  String html_replacement;
  String layout = '';
  var no_rimurc = false;
  List<String> prepend_files = [];
  var pass = false;

  String Function(String) popOptionValue = (String arg) {
    if (args.isEmpty) {
      die("missing $arg option value");
    }
    return args.removeAt(0);
  };

  // Parse command-line options.
  String prepend = '';
  String outfile;
  String arg;
  outer:
  while (args.isNotEmpty) {
    arg = args.removeAt(0);

    switch (arg) {
      case '--help':
      case '-h':
        print('\n' + readResource('manpage.txt'));
        return;
      case '--version':
        print(VERSION + '\n');
        return;
      case '--lint':
      case '-l': // Deprecated in Rimu 10.0.0
        break;
      case '--output':
      case '-o':
        outfile = popOptionValue(arg);
        break;
      case '--pass':
        pass = true;
        break;
      case '--prepend':
      case '-p':
        prepend += popOptionValue(arg) + '\n';
        break;
      case '--prepend-file':
        var prepend_file = popOptionValue(arg);
        prepend_files.add(prepend_file);
        break;
      case '--no-rimurc':
        no_rimurc = true;
        break;
      case '--safe-mode':
      case '--safeMode': // Deprecated in Rimu 7.1.0
        safe_mode = int.parse(popOptionValue(arg));
        if (safe_mode < 0 || safe_mode > 15) {
          die('illegal --safe-mode option value: $safe_mode');
        }
        break;
      case '--html-replacement':
      case '--htmlReplacement': // Deprecated in Rimu 7.1.0
        html_replacement = popOptionValue(arg);
        break;
      // Styling macro definitions shortcut options.
      case '--highlightjs':
      case '--mathjax':
      case '--section-numbers':
      case '--theme':
      case '--title':
      case '--lang':
      case '--toc': // Deprecated in Rimu 8.0.0
      case '--no-toc':
      case '--sidebar-toc': // Deprecated in Rimu 10.0.0
      case '--dropdown-toc': // Deprecated in Rimu 10.0.0
      case '--custom-toc':
      case '--header-ids':
      case '--header-links':
        var macro_value = ['--lang', '--title', '--theme'].contains(arg)
            ? popOptionValue(arg)
            : 'true';
        prepend += "{$arg}='$macro_value'\n";
        break;
      case '--layout':
      case '--styled-name': // Deprecated in Rimu 10.0.0
        layout = popOptionValue(arg);
        if (!['classic', 'flex', 'plain', 'sequel', 'v8'].contains(layout)) {
          die("illegal --layout: $layout"); // NOTE: Imported layouts are not supported.
        }
        prepend += "{--header-ids}='true'\n";
        break;
      case '--styled':
      case '-s':
        prepend += "{--header-ids}='true'\n";
        prepend += "{--no-toc}='true'\n";
        layout = 'sequel';
        break;
      default:
        args.insert(0, arg); // Contains source file names.
        break outer;
    }
  }
  // process.argv contains the list of source files.
  var files = args;
  if (files.isEmpty) {
    files.add(STDIN);
  } else if (files.length == 1 &&
      layout != '' &&
      files[0] != '-' &&
      outfile.isEmpty) {
    // Use the source file name with .html extension for the output file.
    outfile = files[0].substring(0, files[0].lastIndexOf('.')) + '.html';
  }
  if (layout != '') {
    // Envelope source files with header and footer.
    files.insert(0, '${RESOURCE_TAG}${layout}-header.rmu');
    files.add('${RESOURCE_TAG}${layout}-footer.rmu');
  }
  // Prepend $HOME/.rimurc file if it exists.
  if (!no_rimurc && File(RIMURC).existsSync()) {
    prepend_files.insert(0, RIMURC);
  }
  if (prepend != '') {
    prepend_files.add(PREPEND);
  }
  files = List<String>.from(prepend_files);
  files.addAll(files);
  // Convert Rimu source files to HTML.
  String output = '';
  int errors = 0;
  RenderOptions options = RenderOptions();
  if (html_replacement != null) {
    options.htmlReplacement = html_replacement;
  }
  for (String infile in files) {
    if (infile == '-') {
      infile = STDIN;
    }
    var source = '';
    if (infile.startsWith(RESOURCE_TAG)) {
      infile = infile.substring(RESOURCE_TAG.length);
      if (['classic', 'flex', 'sequel', 'plain', 'v8'].contains(layout)) {
        source = readResource(infile);
      } else {
        source = importLayoutFile(infile);
      }
      options.safeMode = 0; // Resources are trusted.
    } else if (infile == PREPEND) {
      source = prepend;
      options.safeMode = 0; // --prepend options are trusted.
    } else {
      if (!File(infile).existsSync()) {
        die('source file does not exist: ' + infile);
      }
      try {
        source = File(infile).readAsStringSync();
      } catch (e) {
        die('source file permission denied: ' + infile);
      }
      // Prepended and ~/.rimurc files are trusted.
      options.safeMode = prepend_files.contains(infile) ? 0 : safe_mode;
    }
    String ext = path.extension(infile);
    // Skip .html and pass-through inputs.
    if (!(ext == '.html' || (pass && infile == STDIN))) {
      options.callback = (message) {
        var msg = message.type + ': ' + infile + ': ' + message.text;
        if (msg.length > 120) {
          msg = msg.substring(0, 117) + '...';
        }
        stderr.writeln(msg);
        if (message.type == 'error') {
          errors += 1;
        }
      };
      source = render(source, options);
    }
    source = source.trim();
    if (source != '') {
      output += source + '\n';
    }
  }
  output = output.trim();
  if (outfile.isEmpty || outfile == '-') {
    stdout.write(output);
  } else {
    File(outfile).writeAsStringSync(output);
  }
  if (errors > 0) {
    die();
  }
}
