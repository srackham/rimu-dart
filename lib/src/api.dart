import 'blockattributes.dart' as blockattributes;
import 'delimitedblocks.dart' as delimitedblocks;
import 'io.dart' as Io;
import 'lineblocks.dart' as lineblocks;
import 'lists.dart' as lists;
import 'macros.dart' as macros;
import 'options.dart' as options;
import 'quotes.dart' as quotes;
import 'replacements.dart' as replacements;

String render(String source) {
  var reader = new Io.Reader(source);
  var writer = new Io.Writer();
  while (!reader.eof()) {
    reader.skipBlankLines();
    if (reader.eof()) break;
    if (lineblocks.render(reader, writer)) continue;
    if (lists.render(reader, writer)) continue;
    if (delimitedblocks.render(reader, writer)) continue;
    // This code should never be executed (normal paragraphs should match anything).
    options.panic('no matching delimited block found');
  }
  return writer.toString();
}

// Set API to default state.
void init() {
  blockattributes.init();
  options.init();
  delimitedblocks.init();
  macros.init();
  quotes.init();
  replacements.init();
}
