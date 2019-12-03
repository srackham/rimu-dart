import 'dart:io';
import 'package:rimu/rimu.dart';
import 'package:path/path.dart' as path;
import 'resources.dart';

/*
  rimuc app implementation.
*/

const VERSION = '11.1.4';
const MANPAGE = r'''NAME
  rimuc - convert Rimu source to HTML

SYNOPSIS
  rimuc [OPTIONS...] [FILES...]

DESCRIPTION
  Reads Rimu source markup from stdin, converts them to HTML
  then writes the HTML to stdout. If FILES are specified
  the Rimu source is read from FILES. The contents of files
  with an .html extension are passed directly to the output.
  An input file named '-' is read from stdin.

  If a file named .rimurc exists in the user's home directory
  then its contents is processed (with --safe-mode 0).
  This behavior can be disabled with the --no-rimurc option.

  Inputs are processed in the following order: .rimurc file,
  --prepend-file options, --prepend options, FILES...

OPTIONS
  -h, --help
    Display help message.

  --html-replacement TEXT
    Embedded HTML is replaced by TEXT when --safe-mode is set to 2.
    Defaults to '<mark>replaced HTML</mark>'.

  --layout LAYOUT
    Generate a styled HTML document. rimuc includes the
    following built-in document layouts:

    'classic': Desktop-centric layout.
    'flex':    Flexbox mobile layout (experimental).
    'plain':   Unstyled HTML layout.
    'sequel':  Responsive cross-device layout.

    If only one source file is specified and the --output
    option is not specified then the output is written to a
    same-named file with an .html extension.
    This option enables --header-ids.

  -s, --styled
    Style output using default layout.
    Shortcut for '--layout sequel --header-ids --no-toc'

  -o, --output OUTFILE
    Write output to file OUTFILE instead of stdout.
    If OUTFILE is a hyphen '-' write to stdout.

  --pass
    Pass the stdin input verbatim to the output.

  -p, --prepend SOURCE
    Process the SOURCE text before all other inputs.
    Rendered with --safe-mode 0.

  --prepend-file PREPEND_FILE
    Process the PREPEND_FILE contents immediately after --prepend
    and .rimurc processing.
    Rendered with --safe-mode 0.

  --no-rimurc
    Do not process .rimurc from the user's home directory.

  --safe-mode NUMBER
    Non-zero safe modes ignore: Definition elements; API option elements;
    HTML attributes in Block Attributes elements.
    Also specifies how to process HTML elements:

    --safe-mode 0 renders HTML (default).
    --safe-mode 1 ignores HTML.
    --safe-mode 2 replaces HTML with --html-replacement option value.
    --safe-mode 3 renders HTML as text.

    Add 4 to --safe-mode to ignore Block Attribute elements.
    Add 8 to --safe-mode to allow Macro Definitions.

  --theme THEME, --lang LANG, --title TITLE, --highlightjs, --mathjax,
  --no-toc, --custom-toc, --section-numbers, --header-ids, --header-links
    Shortcuts for the following prepended macro definitions:

    --prepend "{--custom-toc}='true'"
    --prepend "{--header-ids}='true'"
    --prepend "{--header-links}='true'"
    --prepend "{--highlightjs}='true'"
    --prepend "{--lang}='LANG'"
    --prepend "{--mathjax}='true'"
    --prepend "{--no-toc}='true'"
    --prepend "{--section-numbers}='true'"
    --prepend "{--theme}='THEME'"
    --prepend "{--title}='TITLE'"

  --version
    Print version number.

LAYOUT OPTIONS
  The following options are available when the --layout option
  specifies a built-in layout:

  Option             Description
  _______________________________________________________________
  --custom-toc       Set to a non-blank value if a custom table
                     of contents is used.
  --header-links     Set to a non-blank value to generate h2 and
                     h3 header header links.
  --highlightjs      Set to non-blank value to enable syntax
                     highlighting with Highlight.js.
  --lang             HTML document language attribute value.
  --mathjax          Set to a non-blank value to enable MathJax.
  --no-toc           Set to a non-blank value to suppress table of
                     contents generation.
  --section-numbers  Apply h2 and h3 section numbering.
  --theme            Styling theme. Theme names:
                     'legend', 'graystone', 'vintage'.
  --title            HTML document title.
  _______________________________________________________________
  These options are translated by rimuc to corresponding layout
  macro definitions using the --prepend option.

LAYOUT CLASSES
  The following CSS classes are available for use in Rimu Block
  Attributes elements when the --layout option specifies a
  built-in layout:

  CSS class        Description
  ______________________________________________________________
  align-center     Text alignment center.
  align-left       Text alignment left.
  align-right      Text alignment right.
  bordered         Adds table borders.
  cite             Quote and verse attribution.
  dl-horizontal    Format labeled lists horizontally.
  dl-numbered      Number labeled list items.
  dl-counter       Prepend dl item counter to element content.
  ol-counter       Prepend ol item counter to element content.
  ul-counter       Prepend ul item counter to element content.
  no-auto-toc      Exclude heading from table of contents.
  no-page-break    Avoid page break inside the element.
  no-print         Do not print.
  page-break       Force page break before the element.
  preserve-breaks  Honor line breaks in source text.
  sidebar          Sidebar format (paragraphs, division blocks).
  verse            Verse format (paragraphs, division blocks).
  ______________________________________________________________

PREDEFINED MACROS
  Macro name         Description
  _______________________________________________________________
  --                 Blank macro (empty string).
                     The Blank macro cannot be redefined.
  --header-ids       Set to a non-blank value to generate h1, h2
                     and h3 header id attributes.
  _______________________________________________________________
''';
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

// Skip executable and script paths.
  args.removeAt(0); // Skip executable path.

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
        print(MANPAGE);
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
