class Def {
  String quote; // Single quote character.
  String openTag;
  String closeTag;
  bool spans; // Allow span elements inside quotes.

  Def({this.quote, this.openTag, this.closeTag, this.spans});

  Def.from(Def d) {
    quote = d.quote;
    openTag = d.openTag;
    closeTag = d.closeTag;
    spans = d.spans;
  }
}

List<Def> defs; // Mutable definitions initialized by DEFAULT_DEFS.

final List<Def> DEFAULT_DEFS = [
  Def(quote: '**', openTag: '<strong>', closeTag: '</strong>', spans: true),
  Def(quote: '*', openTag: '<em>', closeTag: '</em>', spans: true),
  Def(quote: '__', openTag: '<strong>', closeTag: '</strong>', spans: true),
  Def(quote: '_', openTag: '<em>', closeTag: '</em>', spans: true),
  Def(quote: '``', openTag: '<code>', closeTag: '</code>', spans: false),
  Def(quote: '`', openTag: '<code>', closeTag: '</code>', spans: false),
  Def(quote: '~~', openTag: '<del>', closeTag: '</del>', spans: true),
];

RegExp quotesRe; // Searches for quoted text.
RegExp unescapeRe; // Searches for escaped quotes.

// Reset definitions to defaults.
void init() {
  // Make shallow copy of DEFAULT_DEFS (list and list objects).
  defs = List<Def>.from(DEFAULT_DEFS.map((def) => Def.from(def)));
  initializeRegExps();
}

// Synthesise re's to find and unescape quotes.
void initializeRegExps() {
  var quotes = defs.map((def) => RegExp.escape(def.quote));
  // $1 is quote character(s), $2 is quoted text.
  // Quoted text cannot begin or end with whitespace.
  // Quoted can span multiple lines.
  // Quoted text cannot end with a backslash.
  quotesRe =
      RegExp(r'\\?(' + quotes.join('|') + r')([^\s\\]|\S[\s\S]*?[^\s\\])\1');
  // $1 is quote character(s).
  unescapeRe = RegExp(r'\\(' + quotes.join('|') + ')');
}

// Return the quote definition corresponding to 'quote' character, return null if not found.
Def getDefinition(String quote) {
  return defs.firstWhere((def) => def.quote == quote, orElse: () => null);
}

// Update existing or add new quote definition.
void setDefinition(Def def) {
  var d = getDefinition(def.quote);
  if (d != null) {
    // Update existing definition.
    d.openTag = def.openTag;
    d.closeTag = def.closeTag;
    d.spans = def.spans;
  } else {
    // Double-quote definitions are prepended to the array so they are matched
    // before single-quote definitions (which are appended to the array).
    if (def.quote.length == 2) {
      defs.insert(0, def);
    } else {
      defs.add(def);
    }
    initializeRegExps();
  }
}

// Strip backslashes from quote characters.
String unescape(String s) {
  return s.replaceAllMapped(unescapeRe, (m) => m[1]);
}
