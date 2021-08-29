import 'options.dart' as options;
import 'spans.dart' as spans;

// Matches a line starting with a macro invocation. $1 = macro invocation.
final MATCH_LINE = RegExp(r'^({(?:[\w\-]+)(?:[!=|?](?:|.*?[^\\]))?}).*$');
// Match single-line macro definition. $1 = name, $2 = delimiter, $3 = value.
final LINE_DEF = RegExp(r"^\\?{([\w\-]+\??)}\s*=\s*'(.*)'$");
// Match multi-line macro definition literal value open delimiter. $1 is first line of macro.
final DEF_OPEN = RegExp(r"^\\?{[\w\-]+\??}\s*=\s*'(.*)$");
final DEF_CLOSE = RegExp(r"^(.*)'$");

class Macro {
  String name;
  String value;

  Macro(this.name, [this.value = '']);
}

final List<Macro> defs = [];

// Reset definitions to defaults.
void init() {
  // Initialize predefined macros.
  defs.clear();
  defs.add(Macro('--'));
  defs.add(Macro('--header-ids'));
}

// Return named macro value or null if it doesn't exist.
String getValue(String name) {
  for (var def in defs) {
    if (def.name == name) {
      return def.value;
    }
  }
  return null;
}

// Set named macro value or add it if it doesn't exist.
// If the name ends with '?' then don't set the macro if it already exists.
// `quote` is a single character: ' if a literal value, ` if an expression value.
void setValue(String name, String value) {
  if (options.skipMacroDefs()) {
    return; // Skip if a safe mode is set.
  }
  var existential = false;
  if (name.endsWith('?')) {
    name = name.substring(0, name.length - 1); // Strip trailing '?'.
    existential = true;
  }
  if (name == '--' && value != '') {
    options
        .errorCallback('the predefined blank \'--\' macro cannot be redefined');
    return;
  }
  for (var def in defs) {
    if (def.name == name) {
      if (!existential) {
        def.value = value;
      }
      return;
    }
  }
  defs.add(Macro(name, value));
}

// Render macro invocations in text string.
// Render Simple invocations first, followed by Parametized, Inclusion and Exclusion invocations.
String render(String text, {bool silent = false}) {
  final MATCH_COMPLEX = RegExp(r'\\?{([\w\-]+)([!=|?](?:|.*?[^\\]))}',
      dotAll: true); // Parametrized, Inclusion and Exclusion invocations.
  final MATCH_SIMPLE = RegExp(r'\\?{([\w\-]+)()}'); // Simple macro invocation.
  var result = text;
  [MATCH_SIMPLE, MATCH_COMPLEX].forEach((find) {
    result = result.replaceAllMapped(find, (match) {
      if (match[0].startsWith(r'\')) {
        return match[0].substring(1);
      }
      var params = match[2];
      if (params.startsWith('?')) {
        // DEPRECATED: Existential macro invocation.
        if (!silent) {
          options.errorCallback(
              'existential macro invocations are deprecated: ${match[0]}');
        }
        return match[0];
      }
      var name = match[1];
      var value = getValue(name); // Macro value is null if macro is undefined.
      if (value == null) {
        if (!silent) {
          options.errorCallback('undefined macro: ${match[0]}: $text');
        }
        return match[0];
      }
      if (find == MATCH_SIMPLE) {
        return value;
      }
      params = params.replaceAll(r'\}', '}'); // Unescape escaped } characters.
      switch (params[0]) {
        case '|': // Parametrized macro.
          var paramsList = params.substring(1).split('|');
          // Substitute macro parameters.
          // Matches macro definition formal parameters [$]$<param-number>[[\]:<default-param-value>$]
          // 1st group: [$]$
          // 2nd group: <param-number> (1, 2..)
          // 3rd group: [\]:<default-param-value>$
          // 4th group: <default-param-value>
          var PARAM_RE =
              RegExp(r'\\?(\$\$?)(\d+)(\\?:(|.*?[^\\])\$)?', dotAll: true);
          value = value.replaceAllMapped(PARAM_RE, (mr) {
            if (mr[0].startsWith(r'\')) {
              // Unescape escaped macro parameters.
              return mr[0].substring(1);
            }
            var p1 = mr[1];
            var p2 = int.parse(mr[2]);
            var p3 = mr[3] ?? '';
            var p4 = mr[4] ?? '';
            if (p2 == 0) {
              return mr[0]; // $0 is not a valid parameter name.
            }
            // Unassigned parameters are replaced with a blank string.
            var param = (paramsList.length < p2) ? '' : paramsList[p2 - 1];
            if (p3.isNotEmpty) {
              if (p3.startsWith(r'\')) {
                // Unescape escaped default parameter.
                param += p3.substring(1);
              } else {
                if (param == '') {
                  // Assign default parameter value.
                  param = p4;
                  // Unescape escaped $ characters in the default value.
                  param = param.replaceAll(r'\$', r'$');
                }
              }
            }
            if (p1 == r'$$') {
              param = spans.render(param);
            }
            return param;
          });
          return value;
          break;
        case '!': // Exclusion macro.
        case '=': // Inclusion macro.
          var pattern = params.substring(1);
          bool skip;
          try {
            skip = !RegExp('^$pattern\$').hasMatch(value);
          } catch (e) {
            if (!silent) {
              options.errorCallback(
                  'illegal macro regular expression: $pattern: $text');
            }
            return match[0];
          }
          if (params[0] == '!') {
            skip = !skip;
          }
          return skip ? '\u0002' : ''; // Flag line for deletion.
        default:
          options.errorCallback('illegal macro syntax: ${match[0]}');
          return '';
      }
    });
  });
  // Delete lines flagged by Inclusion/Exclusion macros.
  if (result.contains('\u0002')) {
    result =
        result.split('\n').where((line) => !line.contains('\u0002')).join('\n');
  }
  return result;
}
