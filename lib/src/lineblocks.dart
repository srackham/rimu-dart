import 'blockattributes.dart' as blockattributes;
import 'delimitedblocks.dart' as delimitedblocks;
import 'expansion.dart';
import 'utils.dart' as utils;
import 'options.dart' as options;
import 'io.dart' as io;
import 'macros.dart' as macros;
import 'quotes.dart' as quotes;
import 'replacements.dart' as replacements;

class Def {
  RegExp match;
  String replacement;
  String name; // Optional unique identifier.
  bool Function(RegExpMatch match, io.Reader reader)
      verify; // Additional match verification checks.
  String Function(RegExpMatch match, io.Reader reader, Def def) filter;

  Def({this.match, this.replacement, this.name, this.verify, this.filter});
}

List<Def> defs = [
  // Prefix match with backslash to allow escaping.

  // Comment line.
  Def(
    match: RegExp(r'^\\?\/{2}(.*)$'),
  ),
  // Expand lines prefixed with a macro invocation prior to all other processing.
  // macro name = $1, macro value = $2
  Def(
      match: macros.MATCH_LINE,
      verify: (match, reader) {
        if (macros.DEF_OPEN.hasMatch(match[0])) {
          // Do not process macro definitions.
          return false;
        }
        // Silent because any macro expansion errors will be subsequently addressed downstream.
        var value = macros.render(match[0], silent: true);
        if (value.startsWith(match[0]) || value.contains('\n' + match[0])) {
          // The leading macro invocation expansion failed or contains itself.
          // This stops infinite recursion.
          return false;
        }
        // Insert the macro value into the reader just ahead of the cursor.
        reader.lines.insertAll(reader.pos + 1, value.split('\n'));
        return true;
      },
      filter: (match, reader, def) {
        return ''; // Already processed in the `verify` function.
      }),
  // Delimited Block definition.
  // name = $1, definition = $2
  Def(
      match: RegExp(r"^\\?\|([\w\-]+)\|\s*=\s*'(.*)'$"),
      filter: (match, reader, def) {
        if (options.isSafeModeNz()) {
          return ''; // Skip if a safe mode is set.
        }
        var value =
            utils.replaceInline(match[2], ExpansionOptions(macros: true));
        delimitedblocks.setDefinition(match[1], value);
        return '';
      }),
  // Quote definition.
  // quote = $1, openTag = $2, separator = $3, closeTag = $4
  Def(
      match: RegExp(r"^(\S{1,2})\s*=\s*'([^|]*)(\|{1,2})(.*)'$"),
      filter: (match, reader, def) {
        if (options.isSafeModeNz()) {
          return ''; // Skip if a safe mode is set.
        }
        quotes.setDefinition(quotes.Def(
            quote: match[1],
            openTag:
                utils.replaceInline(match[2], ExpansionOptions(macros: true)),
            closeTag:
                utils.replaceInline(match[4], ExpansionOptions(macros: true)),
            spans: match[3] == '|'));
        return '';
      }),
  // Replacement definition.
  // pattern = $1, flags = $2, replacement = $3
  Def(
      match: RegExp(r"^\\?\/(.+)\/([igm]*)\s*=\s*'(.*)'$"),
      filter: (match, reader, def) {
        if (options.isSafeModeNz()) {
          return ''; // Skip if a safe mode is set.
        }
        var pattern = match[1];
        var flags = match[2];
        var replacement = match[3];
        replacement =
            utils.replaceInline(replacement, ExpansionOptions(macros: true));
        replacements.setDefinition(pattern, flags, replacement);
        return '';
      }),
  // Macro definition.
  // name = $1, value = $2
  Def(
      match: macros.LINE_DEF,
      filter: (match, reader, def) {
        var name = match[1];
        var value = match[2];
        value = utils.replaceInline(value, ExpansionOptions(macros: true));
        macros.setValue(name, value);
        return '';
      }),
  // Headers.
  // $1 is ID, $2 is header text.
  Def(
      match: RegExp(r'^\\?([#=]{1,6})\s+(.+?)(?:\s+\1)?$'),
      replacement: r'<h$1>$$2</h$1>',
      filter: (match, reader, def) {
        // var headerIds = macros.getValue('--header-ids') ??
        if ((macros.getValue('--header-ids')?.isNotEmpty ?? false) &&
            blockattributes.id == '') {
          blockattributes.id = blockattributes.slugify(match[2]);
        }
        var result = utils.replaceMatch(
            match, def.replacement, ExpansionOptions(macros: true));
        // Replace $1 with header number e.g. "<h###>" -> "<h3>"
        result =
            result.replaceAll(match[1] + '>', match[1].length.toString() + '>');
        return result;
      }),
  // Block image: <image:src|alt>
  // src = $1, alt = $2
  Def(
    match: RegExp(r'^\\?<image:([^\s|]+)\|([^]+?)>$'),
    replacement: r'<img src="$1" alt="$2">',
  ),
  // Block image: <image:src>
  // src = $1, alt = $1
  Def(
    match: RegExp(r'^\\?<image:([^\s|]+?)>$'),
    replacement: r'<img src="$1" alt="$1">',
  ),
  // DEPRECATED as of 3.4.0.
  // Block anchor: <<#id>>
  // id = $1
  Def(
      match: RegExp(r'^\\?<<#([a-zA-Z][\w\-]*)>>$'),
      replacement: r'<div id="$1"></div>',
      filter: (match, reader, def) {
        if (options.skipBlockAttributes()) {
          return '';
        } else {
          // Default (non-filter) replacement processing.
          return utils.replaceMatch(
              match, def.replacement, ExpansionOptions(macros: true));
        }
      }),
  // Block Attributes.
  // Syntax: .class-names #id [html-attributes] block-options
  Def(
    name: 'attributes',
    match: RegExp(
        r'^\\?\.[a-zA-Z#"\[+-].*$'), // A loose match because Block Attributes can contain macro references.
    verify: (match, reader) {
      return blockattributes.parse(match[0]);
    },
  ),
  // API Option.
  // name = $1, value = $2
  Def(
      match: RegExp(r"^\\?\.(\w+)\s*=\s*'(.*)'$"),
      filter: (match, reader, def) {
        if (!options.isSafeModeNz()) {
          var value =
              utils.replaceInline(match[2], ExpansionOptions(macros: true));
          options.setOption(match[1], value);
        }
        return '';
      }),
];

// If the next element in the reader is a valid line block render it
// and return true, else return false.
bool render(io.Reader reader, io.Writer writer, {List<String> allowed}) {
  if (reader.eof()) {
    options.panic('premature eof');
  }
  allowed ??= [];
  for (var def in defs) {
    if (allowed.isNotEmpty && !allowed.contains(def.name)) {
      continue;
    }
    var match = def.match.firstMatch(reader.cursor);
    if (match != null) {
      if (match[0][0] == r'\') {
        // Drop backslash escape and continue.
        reader.cursor = reader.cursor.substring(1);
        continue;
      }
      if (def.verify != null && !def.verify(match, reader)) {
        continue;
      }
      String text;
      if (def.filter != null) {
        text = def.filter(match, reader, def);
      } else {
        text = (def.replacement != null)
            ? utils.replaceMatch(
                match, def.replacement, ExpansionOptions(macros: true))
            : '';
      }
      if (text.isNotEmpty) {
        text = blockattributes.injectHtmlAttributes(text);
        writer.write(text);
        reader.next();
        if (!reader.eof()) {
          writer.write('\n'); // Add a trailing '\n' if there are more lines.
        }
      } else {
        reader.next();
      }
      return true;
    }
  }
  return false;
}
