import 'options.dart' as options;
import 'package:collection/collection.dart' show IterableExtension;
import 'utils.dart' as utils;

class Def {
  RegExp? match;
  String? replacement;
  String? Function(Match match, Def def)? filter;

  Def({this.match, this.replacement, this.filter});

  Def.from(Def d) {
    match = d.match;
    replacement = d.replacement;
    filter = d.filter;
  }
}

List<Def>? defs; // Mutable definitions initialized by DEFAULT_DEFS.

final List<Def> DEFAULT_DEFS = [
  // Begin match with \\? to allow the replacement to be escaped.
  // Global flag must be set on match re's so that the RegExp lastIndex property is set.
  // Replacements and special characters are expanded in replacement groups ($1..).
  // Replacement order is important.

  // DEPRECATED as of 3.4.0.
  // Anchor: <<#id>>
  Def(
      match: RegExp(r'\\?<<#([a-zA-Z][\w\-]*)>>'),
      replacement: '<span id="\$1"></span>',
      filter: (match, def) {
        if (options.skipBlockAttributes()) {
          return '';
        }
        // Default (non-filter) replacement processing.
        return utils.replaceMatch(match, def.replacement!);
      }),

  // Image: <image:src|alt>
  // src = $1, alt = $2
  Def(
      match: RegExp(r'\\?<image:([^\s|]+)\|(.*?)>', dotAll: true),
      replacement: '<img src="\$1" alt="\$2">'),

  // Image: <image:src>
  // src = $1, alt = $1
  Def(
      match: RegExp(r'\\?<image:([^\s|]+?)>'),
      replacement: '<img src="\$1" alt="\$1">'),

  // Image: ![alt](url)
  // alt = $1, url = $2
  Def(
      match: RegExp(r'\\?!\[([^[]*?)]\((\S+?)\)'),
      replacement: '<img src="\$2" alt="\$1">'),

  // Email: <address|caption>
  // address = $1, caption = $2
  Def(
      match: RegExp(r'\\?<(\S+@[\w.\-]+)\|(.+?)>', dotAll: true),
      replacement: '<a href="mailto:\$1">\$\$2</a>'),

  // Email: <address>
  // address = $1, caption = $1
  Def(
      match: RegExp(r'\\?<(\S+@[\w.\-]+)>'),
      replacement: '<a href="mailto:\$1">\$1</a>'),

  // Open link in new window: ^[caption](url)
  // caption = $1, url = $2
  Def(
      match: RegExp(r'\\?\^\[([^[]*?)]\((\S+?)\)'),
      replacement: '<a href="\$2" target="_blank">\$\$1</a>'),

  // Link: [caption](url)
  // caption = $1, url = $2
  Def(
      match: RegExp(r'\\?\[([^[]*?)]\((\S+?)\)'),
      replacement: '<a href="\$2">\$\$1</a>'),

  // Link: <url|caption>
  // url = $1, caption = $2
  Def(
      match: RegExp(r'\\?<(\S+?)\|(.*?)>', dotAll: true),
      replacement: '<a href="\$1">\$\$2</a>'),

  // HTML inline tags.
  // Match HTML comment or HTML tag.
  // $1 = tag, $2 = tag name
  Def(
      match: RegExp(
          r'\\?(<!--(?:[^<>&]*)?-->|<\/?([a-z][a-z0-9]*)(?:\s+[^<>&]+)?>)',
          caseSensitive: false),
      replacement: '',
      filter: (match, def) {
        return options.htmlSafeModeFilter(
            match[1]); // Matched HTML comment or inline tag.
      }),

  // Link: <url>
  // url = $1
  Def(match: RegExp(r'\\?<([^|\s]+?)>'), replacement: '<a href="\$1">\$1</a>'),

  // Auto-encode (most) raw HTTP URLs as links.
  Def(
      match: RegExp(r'\\?((?:http|https):\/\/[^\s"' r"']*[A-Za-z0-9/#])"),
      replacement: '<a href="\$1">\$1</a>'),

  // Character entity.
  Def(
      match: RegExp(r'\\?(&[\w#][\w]+;)'),
      replacement: '',
      filter: (match, def) {
        return match[1]; // Pass the entity through verbatim.
      }),

  // Line-break (space followed by \ at end of line).
  Def(match: RegExp(r'[\\ ]\\(\n|$)'), replacement: '<br>\$1'),

  // This hack ensures backslashes immediately preceding closing code quotes are rendered
  // verbatim (Markdown behaviour).
  // Works by finding escaped closing code quotes and replacing the backslash and the character
  // preceding the closing quote with itself.
  Def(match: RegExp(r'(\S\\)(?=`)'), replacement: '\$1'),

  // This hack ensures underscores within words rendered verbatim and are not treated as
  // underscore emphasis quotes (GFM behaviour).
  Def(match: RegExp(r'([a-zA-Z0-9]_)(?=[a-zA-Z0-9])'), replacement: '\$1'),
];

// Reset definitions to defaults.
void init() {
  // Make shallow copy of DEFAULT_DEFS (list and list objects).
  defs = List<Def>.from(DEFAULT_DEFS.map((def) => Def.from(def)));
}

// Return the replacment definition matching the regular expresssion pattern , return null if not found.
Def? getDefinition(String pattern) {
  return defs!.firstWhereOrNull((def) => def.match!.pattern == pattern);
}

// Update existing or add new replacement definition.
void setDefinition(String pattern, String flags, String? replacement) {
  var ignoreCase = flags.contains('i') ? true : false;
  var multiLine = flags.contains('m') ? true : false;
  // Flag properties are read-only so have to create new RegExp.
  var regexp =
      RegExp(pattern, multiLine: multiLine, caseSensitive: !ignoreCase);
  var def = getDefinition(pattern);
  if (def != null) {
    // Update existing definition.
    def.match = regexp;
    def.replacement = replacement;
  } else {
    // Append new definition to end of defs list (custom definitons have lower precedence).
    defs!.add(Def(match: regexp, replacement: replacement));
  }
}
