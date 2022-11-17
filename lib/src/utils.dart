import 'expansion.dart';
import 'macros.dart' as macros;
import 'options.dart' as options;
import 'spans.dart' as spans;

String replaceSpecialChars(String s) {
  return s
      .replaceAll('&', '&amp;')
      .replaceAll('>', '&gt;')
      .replaceAll('<', '&lt;');
}

// Replace pattern '$1' or '$$1', '$2' or '$$2'... in `replacement` with corresponding match groups
// from `match`. If pattern starts with one '$' character add specials to `expansionOptions`,
// if it starts with two '$' characters add spans to `expansionOptions`.
String replaceMatch(Match match, String replacement,
    [ExpansionOptions? expansionOptions]) {
  expansionOptions ??= ExpansionOptions();

  return replacement.replaceAllMapped(RegExp(r'(\${1,2})(\d)'), (mr) {
    // Replace $1, $2 ... with corresponding match groups.
    if (mr[1] == r'$$') {
      expansionOptions!.spans = true;
    } else {
      expansionOptions!.specials = true;
    }
    var i = int.parse(mr[2]!); // match group number.
    if (i > match.groupCount) {
      options.errorCallback('undefined replacement group: ' + mr[0]!);
      return '';
    }
    var result = match[i]; // match group text.
    return replaceInline(result, expansionOptions)!;
  });
}

// Replace the inline elements specified in options in text and return the result.
String? replaceInline(String? text, ExpansionOptions expansionOptions) {
  var result = text;
  if (expansionOptions.macros ?? false) {
    result = macros.render(result);
  }
  // Spans also expand special characters.
  if (expansionOptions.spans ?? false) {
    result = spans.render(result);
  } else if (expansionOptions.specials ?? false) {
    result = replaceSpecialChars(result!);
  }
  return result;
}
