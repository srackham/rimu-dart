class Reader {
  late List<String> lines;
  int pos = 0; // Line index of current line.

  Reader(String text) {
    text = text
        .replaceAll('\u0000', ' ') // Used internally by spans package.
        .replaceAll('\u0001', ' ') // Used internally by spans package.
        .replaceAll('\u0002', ' '); // Used internally by macros package.
    // Split lines on newline boundaries.
    // http://stackoverflow.com/questions/1155678/javascript-string-newline-character
    // Split is broken on IE8 e.g. 'X\n\nX'.split(/\n/g).length) returns 2 but should return 3.
    lines = text.split(RegExp(r'\r\n|\r|\n'));
    pos = 0;
  }

  String get cursor {
    assert(!eof());
    return lines[pos];
  }

  set cursor(String value) {
    assert(!eof());
    lines[pos] = value;
  }

  // Return true if the cursor has advanced over all input lines.
  bool eof() {
    return pos >= lines.length;
  }

  // Move cursor to next input line.
  void next() {
    if (!eof()) {
      pos++;
    }
  }

  // Read to the first line matching the re.
  // Return the array of lines preceding the match plus a line containing
  // the $1 match group (if it exists).
  // If an EOF is encountered return all lines.
  // Exit with the reader pointing to the line containing the matched line.
  List<String?> readTo(RegExp? regexp) {
    var result = <String?>[];
    RegExpMatch? match;
    while (!eof()) {
      match = regexp!.firstMatch(cursor);
      if (match != null) {
        if (match.groupCount > 0) {
          result.add(match[1]); // $1
        }
        break;
      }
      result.add(cursor);
      next();
    }
    return result;
  }

  void skipBlankLines() {
    while (!eof() && cursor.trim() == '') {
      next();
    }
  }
}

class Writer {
  late List<String?>
      buffer; // Appending an array is faster than string concatenation.

  Writer() {
    buffer = [];
  }

  void write(String? s) {
    buffer.add(s);
  }

  @override
  String toString() {
    return buffer.join('');
  }
}
