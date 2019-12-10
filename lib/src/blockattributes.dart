import 'package:rimu/src/expansion.dart';
import 'package:rimu/src/options.dart';
import 'package:rimu/src/utils.dart' as utils;

String classes; // Space separated HTML class names.
String id; // HTML element id.
String css; // HTML CSS styles.
String attributes; // Other HTML element attributes.
ExpansionOptions options;

List<String> ids = []; // List of allocated HTML ids.

void init() {
  classes = '';
  id = '';
  css = '';
  attributes = '';
  options = ExpansionOptions();
  ids.clear();
}

bool parse(String attrs) {
  // Parse Block Attributes.
  // class names = $1, id = $2, css-properties = $3, html-attributes = $4, block-options = $5
  var text = attrs;
  text = utils.replaceInline(text, ExpansionOptions(macros: true));
  var m = RegExp(
          r'^\\?\.((?:\s*[a-zA-Z][\w\-]*)+)*(?:\s*)?(#[a-zA-Z][\w\-]*\s*)?(?:\s*)?(?:"(.+?)")?(?:\s*)?(\[.+])?(?:\s*)?([+-][ \w+-]+)?$')
      .firstMatch(text);
  if (m == null) {
    return false;
  }
  if (!skipBlockAttributes()) {
    if (m[1].isNotEmpty) {
      // HTML element class names.
      classes += ' ${m[1].trim()}';
      classes = classes.trim();
    }
    if (m[2].isNotEmpty) {
      // HTML element id.
      id = m[2].trim().substring(1);
    }
    if (m[3].isNotEmpty) {
      // CSS properties.
      if (css.isNotEmpty && !css.endsWith(';')) {
        css += ';';
      }
      css += ' ' + m[3].trim();
      css = css.trim();
    }
    if ((m[4]?.isNotEmpty ?? false) && !isSafeModeNz()) {
      // HTML attributes.
      attributes += ' ' + m[4].substring(1, m[4].length - 1).trim();
      attributes = attributes.trim();
    }
    options.parse(m[5] ?? '');
  }
  return true;
}

// Inject HTML attributes into the HTML `tag` and return result.
// Consume HTML attributes unless the 'tag' argument is blank.
String injectHtmlAttributes(String tag) {
  var result = tag;
  if (result.isEmpty) {
    return result;
  }
  var attrs = '';
  if (classes.isNotEmpty) {
    var match = RegExp(r'^(<[^>]*class=")(.*?)"', caseSensitive: false)
        .firstMatch(result);
    if (match != null) {
      // Inject class names into existing class attribute in first tag.
      result =
          result.replaceFirst(match[0], '${match[1]}${classes} ${match[2]}"');
    } else {
      attrs = 'class="${classes}"';
    }
  }
  if (id.isNotEmpty) {
    id = id.toLowerCase();
    var has_id =
        RegExp(r'^<[^<]*id=".*?"', caseSensitive: false).hasMatch(result);
    if (has_id || ids.contains(id)) {
      errorCallback("duplicate 'id' attribute: ${id}");
    } else {
      ids.insert(0, id);
    }
    if (!has_id) {
      attrs += ' id="${id}"';
    }
  }
  if (css.isNotEmpty) {
    var match = RegExp(r'^(<[^>]*style=")(.*?)"', caseSensitive: false)
        .firstMatch(result);
    if (match != null) {
      // Inject CSS styles into first style attribute in first tag.
      var group2 = match[2].trim();
      if (!group2.endsWith(';')) {
        group2 += ';';
      }
      result = result.replaceFirst(match[0], '${match[1]}${group2} ${css}"');
    } else {
      attrs += ' style="${css}"';
    }
  }
  if (attributes.isNotEmpty) {
    attrs += ' ${attributes}';
  }
  attrs = attrs.trim();
  if (attrs.isNotEmpty) {
    var match = RegExp(r'^<([a-z]+|h[1-6])(?=[ >])', caseSensitive: false)
        .firstMatch(result);
    if (match != null) {
      // Inject attributes after tag name.
      var before = result.substring(0, match[0].length);
      var after = result.substring(match[0].length);
      result = before + ' ' + attrs + after;
    }
  }
  // Consume the attributes.
  classes = '';
  id = '';
  css = '';
  attributes = '';
  return result;
}

String slugify(String text) {
  var slug = text
      .replaceAll(RegExp(r'\W+'),
          "-") // Replace non-alphanumeric characters with dashes.
      .replaceAll(
          RegExp(r'-+'), "-") // Replace multiple dashes with single dash.
      .replaceAll(RegExp(r'(^-)|(-$)'), "") // Trim leading and trailing dashes.
      .toLowerCase();
  if (slug.isEmpty) {
    slug = 'x';
  }
  if (ids.contains(slug)) {
    // Another element already has that id.
    var i = 2;
    while (ids.contains('${slug}-${i}')) {
      i++;
    }
    slug += '-${i}';
  }
  return slug;
}
