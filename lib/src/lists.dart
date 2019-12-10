import 'blockattributes.dart' as blockattributes;
import 'delimitedblocks.dart' as delimitedblocks;
import 'expansion.dart';
import 'lineblocks.dart' as lineblocks;
import 'options.dart' as options;
import 'io.dart' as io;
import 'utils.dart' as utils;

class Def {
  RegExp match;
  String listOpenTag;
  String listCloseTag;
  String itemOpenTag;
  String itemCloseTag;
  String termOpenTag; // Definition lists only.
  String termCloseTag; // Definition lists only.

  Def(
      {this.match,
      this.listOpenTag,
      this.listCloseTag,
      this.itemOpenTag,
      this.itemCloseTag,
      this.termOpenTag,
      this.termCloseTag});
}

// Information about a matched list item element.
class ItemInfo {
  RegExpMatch match;
  Def def;
  String id; // List ID.
}

final List<Def> defs = [
  // Prefix match with backslash to allow escaping.

  // Unordered lists.
  // $1 is list ID $2 is item text.
  Def(
      match: RegExp(r'^\\?\s*(-|\+|\*{1,4})\s+(.*)$'),
      listOpenTag: '<ul>',
      listCloseTag: '</ul>',
      itemOpenTag: '<li>',
      itemCloseTag: '</li>'),
  // Ordered lists.
  // $1 is list ID $2 is item text.
  Def(
      match: RegExp(r'^\\?\s*(?:\d*)(\.{1,4})\s+(.*)$'),
      listOpenTag: '<ol>',
      listCloseTag: '</ol>',
      itemOpenTag: '<li>',
      itemCloseTag: '</li>'),
  // Definition lists.
  // $1 is term, $2 is list ID, $3 is definition.
  Def(
      match: RegExp(r'^\\?\s*(.*[^:])(:{2,4})(|\s+.*)$'),
      listOpenTag: '<dl>',
      listCloseTag: '</dl>',
      itemOpenTag: '<dd>',
      itemCloseTag: '</dd>',
      termOpenTag: '<dt>',
      termCloseTag: '</dt>'),
];

List<String> ids = []; // Stack of open list IDs.

bool render(io.Reader reader, io.Writer writer) {
  if (reader.eof()) {
    options.panic('premature eof');
  }
  ItemInfo startItem;
  startItem = matchItem(reader);
  if (startItem == null) {
    return false;
  }
  ids = [];
  renderList(startItem, reader, writer);
  // ids should now be empty.
  if (ids.isNotEmpty) {
    options.panic('list stack failure');
  }
  return true;
}

ItemInfo renderList(ItemInfo item, io.Reader reader, io.Writer writer) {
  ids.add(item.id);
  writer.write(blockattributes.injectHtmlAttributes(item.def.listOpenTag));
  ItemInfo nextItem;
  while (true) {
    nextItem = renderListItem(item, reader, writer);
    if (nextItem == null || nextItem.id != item.id) {
      // End of list or next item belongs to parent list.
      writer.write(item.def.listCloseTag);
      ids.removeLast();
      return nextItem;
    }
    item = nextItem;
  }
}

// Render the current list item, return the next list item or null if there are no more items.
ItemInfo renderListItem(ItemInfo item, io.Reader reader, io.Writer writer) {
  var def = item.def;
  var match = item.match;
  String text;
  if (match.groupCount == 3) {
    // 3 match groups => definition list.
    writer.write(blockattributes.injectHtmlAttributes(def.termOpenTag));
    text = utils.replaceInline(
        match[1], ExpansionOptions(macros: true, spans: true));
    writer.write(text);
    writer.write(def.termCloseTag);
    writer.write(def.itemOpenTag);
  } else {
    writer.write(blockattributes.injectHtmlAttributes(def.itemOpenTag));
  }
  // Process item text from first line.
  var itemLines = io.Writer();
  text = match[match.groupCount];
  itemLines.write(text + '\n');
  // Process remainder of list item i.e. item text, optional attached block, optional child list.
  reader.next();
  var attachedLines = io.Writer();
  int blankLines;
  bool attachedDone = false;
  ItemInfo nextItem;
  while (true) {
    blankLines = consumeBlockAttributes(reader, attachedLines);
    if (blankLines >= 2 || blankLines == -1) {
      // EOF or two or more blank lines terminates list.
      nextItem = null;
      break;
    }
    nextItem = matchItem(reader);
    if (nextItem != null) {
      if (ids.contains(nextItem.id)) {
        // Next item belongs to current list or a parent list.
      } else {
        // Render child list.
        nextItem = renderList(nextItem, reader, attachedLines);
      }
      break;
    }
    if (attachedDone) {
      break; // Multiple attached blocks are not permitted.
    }
    if (blankLines == 0) {
      var savedIds = ids;
      ids = [];
      if (delimitedblocks.render(reader, attachedLines,
          ['comment', 'code', 'division', 'html', 'quote'])) {
        attachedDone = true;
      } else {
        // Item body line.
        itemLines.write(reader.cursor + '\n');
        reader.next();
      }
      ids = savedIds;
    } else if (blankLines == 1) {
      if (delimitedblocks
          .render(reader, attachedLines, ['indented', 'quote-paragraph'])) {
        attachedDone = true;
      } else {
        break;
      }
    }
  }
  // Write item text.
  text = itemLines.toString().trim();
  text = utils.replaceInline(text, ExpansionOptions(macros: true, spans: true));
  writer.write(text);
  // Write attachment and child list.
  writer.buffer.addAll(attachedLines.buffer);
  // Close list item.
  writer.write(def.itemCloseTag);
  return nextItem;
}

// Consume blank lines and Block Attributes.
// Return number of blank lines read or -1 if EOF.
int consumeBlockAttributes(io.Reader reader, io.Writer writer) {
  int blanks = 0;
  while (true) {
    if (reader.eof()) {
      return -1;
    }
    if (lineblocks.render(reader, writer, allowed: ['attributes'])) {
      continue;
    }
    if (reader.cursor != '') {
      return blanks;
    }
    blanks++;
    reader.next();
  }
}

// Check if the line at the reader cursor matches a list related element.
// Unescape escaped list items in reader.
// If it does not match a list related element return null.
ItemInfo matchItem(io.Reader reader) {
  // Check if the line matches a List definition.
  if (reader.eof()) {
    return null;
  }
  ItemInfo item = ItemInfo(); // ItemInfo factory.
  // Check if the line matches a list item.
  for (var def in defs) {
    var match = def.match.firstMatch(reader.cursor);
    if (match != null) {
      if (match[0][0] == r'\') {
        reader.cursor = reader.cursor.substring(1); // Drop backslash.
        return null;
      }
      item.match = match;
      item.def = def;
      // The second to last match group is the list ID.
      item.id = match[match.groupCount - 1];
      return item;
    }
  }
  return null;
}
