import 'options.dart' as options;

class ExpansionOptions {
  // Processing priority (highest to lowest): container, skip, spans and specials.
  // If spans is true then both spans and specials are processed.
  // They are assumed false if they are not explicitly defined.
  // If a custom filter is specified their use depends on the filter.
  bool? macros;
  bool? container;
  bool? skip;
  bool? spans; // Span substitution also expands special characters.
  bool? specials;

  @override
  bool operator ==(Object other) =>
      other is ExpansionOptions &&
      macros == other.macros &&
      container == other.container &&
      skip == other.skip &&
      spans == other.spans &&
      specials == other.specials;

  ExpansionOptions(
      {this.macros, this.container, this.skip, this.spans, this.specials});

  ExpansionOptions.from(ExpansionOptions? other) {
    merge(other);
  }

  void merge(ExpansionOptions? from) {
    if (from == null) {
      return;
    }
    macros = from.macros ?? macros;
    container = from.container ?? container;
    skip = from.skip ?? skip;
    spans = from.spans ?? spans;
    specials = from.specials ?? specials;
  }

  // Parse block-options string into blockOptions.
  void parse(String opts) {
    if (opts.isNotEmpty) {
      for (var opt in opts.trim().split(RegExp(r'\s+'))) {
        if (options.isSafeModeNz() && opt == '-specials') {
          options.errorCallback('-specials block option not valid in safeMode');
          continue;
        }
        if (RegExp(r'^[+-](macros|spans|specials|container|skip)$')
            .hasMatch(opt)) {
          var value = opt[0] == '+';
          switch (opt.substring(1)) {
            case 'macros':
              macros = value;
              break;
            case 'spans':
              spans = value;
              break;
            case 'specials':
              specials = value;
              break;
            case 'container':
              container = value;
              break;
            case 'skip':
              skip = value;
              break;
          }
        } else {
          options.errorCallback('illegal block option: ' + opt);
        }
      }
    }
  }
}
