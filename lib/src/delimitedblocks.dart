import 'api.dart' as api;
import 'blockattributes.dart' as blockattributes;
import 'expansion.dart' show ExpansionOptions;
import 'io.dart' as io;
import 'macros.dart' as macros;
import 'options.dart' as options;
import 'utils.dart' as utils;

final MATCH_INLINE_TAG = RegExp(
    r'^(a|abbr|acronym|address|b|bdi|bdo|big|blockquote|br|cite|code|del|dfn|em|i|img|ins|kbd|mark|q|s|samp|small|span|strike|strong|sub|sup|time|tt|u|var|wbr)$',
    caseSensitive: false);

typedef Verify = bool Function(
    RegExpMatch match); // Additional match verification checks.
typedef DelimiterFilter = String Function(RegExpMatch match,
    Def def); // Process opening delimiter. Return any delimiter content.
typedef ContentFilter = String Function(
    String text, RegExpMatch match, ExpansionOptions expansionOptions);

// Multi-line block element definition.
class Def {
  String name; // Unique identifier.
  RegExp openMatch;
  RegExp closeMatch; // $1 (if defined) is appended to block content.
  String openTag;
  String closeTag;
  Verify verify; // Additional match verification checks.
  DelimiterFilter
      delimiterFilter; // Process opening delimiter. Return any delimiter content.
  ContentFilter contentFilter;
  ExpansionOptions expansionOptions;

  Def(
      {this.name,
      this.openMatch,
      this.closeMatch,
      this.openTag,
      this.closeTag,
      this.verify,
      this.delimiterFilter,
      this.contentFilter,
      this.expansionOptions});

  Def.from(Def other) {
    name = other.name;
    openMatch = other.openMatch;
    closeMatch = other.closeMatch;
    openTag = other.openTag;
    closeTag = other.closeTag;
    verify = other.verify;
    delimiterFilter = other.delimiterFilter;
    contentFilter = other.contentFilter;
    expansionOptions = ExpansionOptions.from(other.expansionOptions);
  }
}

List<Def> defs; // Mutable definitions initialized by DEFAULT_DEFS.

final List<Def> DEFAULT_DEFS = [
  // Delimited blocks cannot be escaped with a backslash.

  // Multi-line macro literal value definition.
  Def(
    name: 'macro-definition',
    openMatch: macros.DEF_OPEN, // $1 is first line of macro.
    closeMatch: macros.DEF_CLOSE,
    openTag: '',
    closeTag: '',
    expansionOptions: ExpansionOptions(macros: true),
    delimiterFilter: delimiterTextFilter,
    contentFilter: macroDefContentFilter,
  ),
  // Comment block.
  Def(
      name: 'comment',
      openMatch: RegExp(r'^\\?\/\*+$'),
      closeMatch: RegExp(r'^\*+\/$'),
      openTag: '',
      closeTag: '',
      expansionOptions: ExpansionOptions(
          skip: true, specials: true // Fall-back if skip is disabled.
          )),
  // Division block.
  Def(
      name: 'division',
      openMatch: RegExp(
          r'^\\?(\.{2,})([\w\s-]*)$'), // $1 is delimiter text, $2 is optional class names.
      openTag: '<div>',
      closeTag: '</div>',
      expansionOptions: ExpansionOptions(
          container: true, specials: true // Fall-back if container is disabled.
          ),
      delimiterFilter: classInjectionFilter),
  // Quote block.
  Def(
      name: 'quote',
      openMatch: RegExp(
          r'^\\?("{2,}|>{2,})([\w\s-]*)$'), // $1 is delimiter text, $2 is optional class names.
      openTag: '<blockquote>',
      closeTag: '</blockquote>',
      expansionOptions: ExpansionOptions(
          container: true, specials: true // Fall-back if container is disabled.
          ),
      delimiterFilter: classInjectionFilter),
  // Code block.
  Def(
      name: 'code',
      openMatch: RegExp(
          r'^\\?(-{2,}|`{2,})([\w\s-]*)$'), // $1 is delimiter text, $2 is optional class names.
      openTag: '<pre><code>',
      closeTag: '</code></pre>',
      expansionOptions: ExpansionOptions(macros: false, specials: true),
      verify: (match) {
        // The deprecated '-' delimiter does not support appended class names.
        return !(match[1][0] == '-' && match[2].trim() != '');
      },
      delimiterFilter: classInjectionFilter),
  // HTML block.
  Def(
    name: 'html',
    // Block starts with HTML comment, DOCTYPE directive or block-level HTML start or end tag.
    // $1 is first line of block.
    // $2 is the alphanumeric tag name.
    openMatch: RegExp(
        r'^(<!--.*|<!DOCTYPE(?:\s.*)?|<\/?([a-z][a-z0-9]*)(?:[\s>].*)?)$',
        caseSensitive: false),
    closeMatch: RegExp(r'^$'),
    openTag: '',
    closeTag: '',
    expansionOptions: ExpansionOptions(macros: true),
    verify: (match) {
      // Return false if the HTML tag is an inline (non-block) HTML tag.
      if (match[2]?.isNotEmpty ?? false) {
        // Matched alphanumeric tag name.
        return !MATCH_INLINE_TAG.hasMatch(match[2]);
      } else {
        return true; // Matched HTML comment or doctype tag.
      }
    },
    delimiterFilter: delimiterTextFilter,
    contentFilter: (text, match, expansionOptions) =>
        options.htmlSafeModeFilter(text),
  ),
  // Indented paragraph.
  Def(
      name: 'indented',
      openMatch: RegExp(r'^\\?(\s+\S.*)$'), // $1 is first line of block.
      closeMatch: RegExp(r'^$'),
      openTag: '<pre><code>',
      closeTag: '</code></pre>',
      expansionOptions: ExpansionOptions(macros: false, specials: true),
      delimiterFilter: delimiterTextFilter,
      contentFilter: (text, match, expansionOptions) {
        // Strip indent from start of each line.
        var first_indent = text.indexOf(RegExp(r'\S'));
        return text.split('\n').map((line) {
          // Strip first line indent width or up to first non-space character.
          var indent = line.indexOf(RegExp(r'\S|$'));
          if (indent > first_indent) {
            indent = first_indent;
          }
          return line.substring(indent);
        }).join('\n');
      }),
  // Quote paragraph.
  Def(
      name: 'quote-paragraph',
      openMatch: RegExp(r'^\\?(>.*)$'), // $1 is first line of block.
      closeMatch: RegExp(r'^$'),
      openTag: '<blockquote><p>',
      closeTag: '</p></blockquote>',
      expansionOptions: ExpansionOptions(
          macros: true,
          spans: true,
          specials: true // Fall-back if spans is disabled.
          ),
      delimiterFilter: delimiterTextFilter,
      contentFilter: (text, match, expansionOptions) {
        // Strip leading > from start of each line and unescape escaped leading >.
        return text
            .split('\n')
            .map((line) => line
                .replaceAll(RegExp(r'^>'), '')
                .replaceAll(RegExp(r'^\\>'), '>'))
            .join('\n');
      }),
  // Paragraph (lowest priority, cannot be escaped).
  Def(
      name: 'paragraph',
      openMatch: RegExp(r'(.*)'), // $1 is first line of block.
      closeMatch: RegExp(r'^$'),
      openTag: '<p>',
      closeTag: '</p>',
      expansionOptions: ExpansionOptions(
          macros: true,
          spans: true,
          specials: true // Fall-back if spans is disabled.
          ),
      delimiterFilter: delimiterTextFilter),
];

// Reset definitions to defaults.
void init() {
  defs = DEFAULT_DEFS.map((def) => Def.from(def)).toList();
}

// If the next element in the reader is a valid delimited block render it
// and return true, else return false.
bool render(io.Reader reader, io.Writer writer, [List<String> allowed]) {
  if (reader.eof()) {
    options.panic('premature eof');
  }
  for (var def in defs) {
    if (allowed != null && !allowed.contains(def.name)) {
      continue;
    }
    var match = def.openMatch.firstMatch(reader.cursor);
    if (match == null) {
      continue;
    }
    // Escape non-paragraphs.
    if (match[0][0] == '\\' && def.name != 'paragraph') {
      // Drop backslash escape and continue.
      reader.cursor = reader.cursor.substring(1);
      continue;
    }
    if (def.verify != null && !def.verify(match)) {
      continue;
    }
    // Process opening delimiter.
    var delimiterText =
        (def.delimiterFilter != null) ? def.delimiterFilter(match, def) : '';
    // Read block content into lines.
    var lines = <String>[];
    if (delimiterText.isNotEmpty) {
      lines.add(delimiterText);
    }
    // Read content up to the closing delimiter.
    reader.next();
    var content = reader.readTo(def.closeMatch ?? def.openMatch);
    if (reader.eof() &&
        ["code", "comment", "division", "quote"].contains(def.name)) {
      options.errorCallback(
        "unterminated ${def.name} block: ${match[0]}",
      );
    }
    reader.next(); // Skip closing delimiter.
    lines.addAll(content);
    // Calculate block expansion options.
    var expansionOptions = ExpansionOptions.from(def.expansionOptions);
    expansionOptions.merge(blockattributes.options);
    // Translate block.
    if (!(expansionOptions.skip ?? false)) {
      var text = lines.join('\n');
      if (def.contentFilter != null) {
        text = def.contentFilter(text, match, expansionOptions);
      }
      var opentag = def.openTag;
      if (def.name == 'html') {
        text = blockattributes.injectHtmlAttributes(text);
      } else {
        opentag = blockattributes.injectHtmlAttributes(opentag);
      }
      if (expansionOptions.container ?? false) {
        blockattributes.options.container = null; // Consume before recursion.
        text = api.render(text);
      } else {
        text = utils.replaceInline(text, expansionOptions);
      }
      var closetag = def.closeTag;
      if (def.name == 'division' && opentag == '<div>') {
        // Drop div tags if the opening div has no attributes.
        opentag = '';
        closetag = '';
      }
      writer.write(opentag);
      writer.write(text);
      writer.write(closetag);
      if (!reader.eof() && (opentag + text + closetag).isNotEmpty) {
        // Add a trailing '\n' if we've written a non-blank line and there are more source lines left.
        writer.write('\n');
      }
    }
    // Reset consumed Block Attributes expansion options.
    blockattributes.options = ExpansionOptions();
    return true;
  }
  return false; // No matching delimited block found.
}

// Return block definition or null if not found.
Def getDefinition(String name) {
  return defs.firstWhere((def) => def.name == name, orElse: () => null);
}

// Update existing named definition.
// Value syntax: <open-tag>|<close-tag> block-options
void setDefinition(String name, String value) {
  var def = getDefinition(name);
  if (def == null) {
    options
        .errorCallback("illegal delimited block name: $name: |$name|='$value'");
    return;
  }
  var match =
      RegExp(r'^(?:(<[a-zA-Z].*>)\|(<[a-zA-Z/].*>))?(?:\s*)?([+-][ \w+-]+)?$')
          .firstMatch(value.trim());
  if (match == null) {
    options
        .errorCallback("illegal delimited block definition: |$name|='$value'");
    return;
  }
  if (match[1] != null) {
    // Open and close tags are defined.
    def.openTag = match[1];
    def.closeTag = match[2];
  }
  if (match[3] != null) {
    def.expansionOptions.parse(match[3]);
  }
}

// delimiterFilter that returns opening delimiter line text from match group $1.
String delimiterTextFilter(RegExpMatch match, Def def) {
  return match[1];
}

// delimiterFilter for code, division and quote blocks.
// Inject $2 into block class attribute, set close delimiter to $1.
String classInjectionFilter(RegExpMatch match, Def def) {
  var p1 = match[2].trim();
  if (p1.isNotEmpty) {
    blockattributes.classes = p1;
  }
  def.closeMatch = RegExp('^' + RegExp.escape(match[1]) + r'$');
  return '';
}

// contentFilter for multi-line macro definitions.
String macroDefContentFilter(
    String text, RegExpMatch match, ExpansionOptions expansionOptions) {
  var name = RegExp(r'^{([\w\-]+\??)}')
      .firstMatch(match[0])[1]; // Extract macro name from opening delimiter.
  text = text.replaceAll(
      RegExp(r"' *\\\n"), "'\n"); // Unescape line-continuations.
  text = text.replaceAllMapped(RegExp(r"(' *[\\]+)\\\n"),
      (match) => '${match[1]}\n'); // Unescape escaped line-continuations.
  text =
      utils.replaceInline(text, expansionOptions); // Expand macro invocations.
  macros.setValue(name, text);
  return '';
}
