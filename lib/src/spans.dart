/*
 This module renders inline text containing Quote and Replacement elements.

 Quote and replacement processing involves splitting the source text into
 fragments where at the points where quotes and replacements occur then splicing fragments
 containing output markup into the breaks. A fragment is flagged as 'done' to
 exclude it from further processing.

 Once all quotes and replacements are processed fragments not yet flagged as
 'done' have special characters (&, <, >) replaced with corresponding special
 character entities. The fragments are then reassembled (defraged) into a
 resultant HTML string.
 */

import 'quotes.dart' as quotes;
import 'replacements.dart' as replacements;
import 'utils.dart' as utils;

class Fragment {
  String? text;
  bool? done;
  String? verbatim; // Replacements text rendered verbatim.

  Fragment({this.text, this.done, this.verbatim});
}

String render(String? source) {
  var result = preReplacements(source);
  var fragments = [Fragment(text: result, done: false)];
  fragments = fragQuotes(fragments);
  fragSpecials(fragments);
  result = defrag(fragments);
  return postReplacements(result);
}

// Converts fragments to a string.
String defrag(List<Fragment> fragments) {
  return fragments.fold('', (result, fragment) => result + fragment.text!);
}

// Fragment quotes in all fragments and return resulting fragments array.
List<Fragment> fragQuotes(List<Fragment> fragments) {
  final result = <Fragment>[];
  for (var fragment in fragments) {
    result.addAll(fragQuote(fragment));
  }
  // Strip backlash from escaped quotes in non-done fragments.
  for (var fragment in result) {
    if (!fragment.done!) {
      fragment.text = quotes.unescape(fragment.text!);
    }
  }
  return result;
}

// Fragment quotes in a single fragment and return resulting fragments array.
List<Fragment> fragQuote(Fragment fragment) {
  if (fragment.done!) {
    return [fragment];
  }
  // Find first matched quote in fragment text.
  String quote;
  RegExpMatch? match;
  var startIndex = 0;
  var nextIndex = 0;
  while (true) {
    match = quotes.quotesRe.firstMatch(fragment.text!.substring(nextIndex));
    if (match == null) {
      return [fragment];
    }
    quote = match[1]!;
    // Check if quote is escaped.
    if (match[0]!.startsWith(r'\')) {
      // Restart search after escaped opening quote.
      nextIndex += match.start + quote.length + 1;
      continue;
    }
    startIndex = nextIndex + match.start;
    nextIndex += match.end;
    break;
  }
  var result = <Fragment>[];
  // Arrive here if we have a matched quote.
  // The quote splits the input fragment into 5 or more output fragments:
  // Text before the quote, left quote tag, quoted text, right quote tag and text after the quote.
  final def = quotes.getDefinition(match[1])!;
  // Check for same closing quote one character further to the right.
  var quoted = match[2]!;
  while (nextIndex < fragment.text!.length &&
      fragment.text![nextIndex] == quote[0]) {
    // Move to closing quote one character to right.
    quoted += quote[0];
    nextIndex += 1;
  }
  final before = fragment.text!.substring(0, startIndex);
  final after = fragment.text!.substring(nextIndex);
  result.add(Fragment(text: before, done: false));
  result.add(Fragment(text: def.openTag, done: true));
  if (!def.spans!) {
    // Spans are disabled so render the quoted text verbatim.
    quoted = utils.replaceSpecialChars(quoted);
    quoted = quoted.replaceAll(
        '\u0000', '\u0001'); // Substitute verbatim replacement placeholder.
    result.add(Fragment(text: quoted, done: true));
  } else {
    // Recursively process the quoted text.
    result.addAll(fragQuote(Fragment(text: quoted, done: false)));
  }
  result.add(Fragment(text: def.closeTag, done: true));
  // Recursively process the following text.
  result.addAll(fragQuote(Fragment(text: after, done: false)));
  return result;
}

// Stores placeholder replacement fragments saved by `preReplacements()` and restored by `postReplacements()`.
final List<Fragment> savedReplacements = [];

// Return text with replacements replaced with a placeholder character (see `postReplacements()`):
// '\u0000' is placeholder for expanded replacement text.
// '\u0001' is placeholder for unexpanded replacement text (replacements that occur within quotes are rendered verbatim).
String preReplacements(String? text) {
  savedReplacements.clear();
  final fragments = fragReplacements([Fragment(text: text, done: false)]);
  // Reassemble text with replacement placeholders.
  return fragments.fold('', (result, fragment) {
    if (fragment.done!) {
      savedReplacements.add(fragment); // Save replaced text.
      return result + '\u0000'; // Placeholder for replaced text.
    } else {
      return result + fragment.text!;
    }
  });
}

// Replace replacements placeholders with replacements text from savedReplacements[].
String postReplacements(String text) {
  return text.replaceAllMapped(RegExp(r'[\u0000\u0001]'), (match) {
    final fragment = savedReplacements.removeAt(0);
    return (match[0] == '\u0000')
        ? fragment.text!
        : utils.replaceSpecialChars(fragment.verbatim ?? '');
  });
}

// Fragment replacements in all fragments and return resulting fragments array.
List<Fragment> fragReplacements(List<Fragment> fragments) {
  var result = List<Fragment>.from(fragments);
  for (var def in replacements.defs!) {
    final tmp = <Fragment>[];
    for (var fragment in result) {
      tmp.addAll(fragReplacement(fragment, def));
    }
    result = List<Fragment>.from(tmp);
  }
  return result;
}

// Fragment replacements in a single fragment for a single replacement definition.
// Return resulting fragments array.
List<Fragment> fragReplacement(Fragment fragment, replacements.Def def) {
  if (fragment.done!) {
    return [fragment];
  }
  final match = def.match!.firstMatch(fragment.text!);
  if (match == null) {
    return [fragment];
  }
  // Arrive here if we have a matched replacement.
  // The replacement splits the input fragment into 3 output fragments:
  // Text before the replacement, replaced text and text after the replacement.
  final before = fragment.text!.substring(0, match.start);
  final after = (match.end >= fragment.text!.length)
      ? ''
      : fragment.text!.substring(match.end);
  final result = <Fragment>[];
  result.add(Fragment(text: before, done: false));
  String? replacement;
  if (match[0]!.startsWith(r'\')) {
    // Remove leading backslash.
    replacement = utils.replaceSpecialChars(match[0]!.substring(1));
  } else {
    if (def.filter == null) {
      replacement = utils.replaceMatch(match, def.replacement!);
    } else {
      replacement = def.filter!(match, def);
    }
  }
  result.add(Fragment(text: replacement, done: true, verbatim: match[0]));
  // Recursively process the remaining text.
  result.addAll(fragReplacement(Fragment(text: after, done: false), def));
  return result;
}

void fragSpecials(List<Fragment> fragments) {
  // Replace special characters in all non-done fragments.
  fragments.where((fragment) => !fragment.done!).forEach(
      (fragment) => fragment.text = utils.replaceSpecialChars(fragment.text!));
}
