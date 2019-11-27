String render(String source) {
  return '<p>Hello <em>Rimu</em>!</p>\n';
}

// Set API to default state.
init() {}

/* TRANSLATED api.ts

import "utils.dart" show BlockAttributes;
import "delimitedblocks.dart" as DelimitedBlocks;
import "io.dart" as Io;
import "lineblocks.dart" as LineBlocks;
import "lists.dart" as Lists;
import "macros.dart" as Macros;
import "options.dart" as Options;
import "quotes.dart" as Quotes;
import "replacements.dart" as Replacements;

String render(String source) {
  var reader = new Io.Reader(source);
  var writer = new Io.Writer();
  while (!reader.eof()) {
    reader.skipBlankLines();
    if (reader.eof()) break;
    if (LineBlocks.render(reader, writer)) continue;
    if (Lists.render(reader, writer)) continue;
    if (DelimitedBlocks.render(reader, writer)) continue;
    // This code should never be executed (normal paragraphs should match anything).
    Options.panic("no matching delimited block found");
  }
  return writer.toString();
}

// Set API to default state.
void init() {
  BlockAttributes.init();
  Options.init();
  DelimitedBlocks.init();
  Macros.init();
  Quotes.init();
  Replacements.init();
}
*/
