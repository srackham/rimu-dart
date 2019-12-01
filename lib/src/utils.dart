// MOCK
class ExpansionOptions {}

String replaceSpecialChars(String s) {
  return s
      .replaceAll('&', '&amp;')
      .replaceAll('>', '&gt;')
      .replaceAll('<', '&lt;');
}

// MOCK

// Replace pattern '$1' or '$$1', '$2' or '$$2'... in `replacement` with corresponding match groups
// from `match`. If pattern starts with one '$' character add specials to `expansionOptions`,
// if it starts with two '$' characters add spans to `expansionOptions`.
String replaceMatch(Match match,
                             String replacement,
                             {ExpansionOptions expansionOptions}){
                               return 'MOCK';
                             }