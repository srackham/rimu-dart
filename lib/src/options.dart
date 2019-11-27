import 'api.dart' as api;
import 'utils.dart' as utils;

class RenderOptions {
  int safeMode;
  String htmlReplacement;
  bool reset;
  CallbackFunction callback;

  RenderOptions(
      {this.safeMode, this.htmlReplacement, this.reset, this.callback});
}

class CallbackMessage {
  String type;
  String text;

  CallbackMessage(this.type, this.text);
}

typedef CallbackFunction = Function(CallbackMessage message);

// Global option values.
int safeMode;
String htmlReplacement;
CallbackFunction callback;

// Reset options to default values.
init() {
  safeMode = 0;
  htmlReplacement = '<mark>replaced HTML</mark>';
  callback = null;
}

// Return true if safeMode is non-zero.
bool isSafeModeNz() {
  return safeMode != 0;
}

int getSafeMode() {
  return safeMode;
}

// Return true if Block Attribute elements are ignored.
bool skipBlockAttributes() {
  return safeMode != 0 && (safeMode & 0x4) != 0;
}

setSafeMode(var value) {
  int n = int.tryParse(value.toString());
  if (n == null || n < 0 || n > 15) {
    errorCallback('illegal safeMode API option value: ' + value);
    return;
  }
  safeMode = n;
}

setHtmlReplacement(String value) {
  htmlReplacement = value;
}

setReset(var value) {
  if (value == false || value == 'false') {
    return;
  } else if (value == true || value == 'true') {
    api.init();
  } else {
    errorCallback('illegal reset API option value: ' + value);
  }
}

updateOptions(RenderOptions options) {
  callback ??= options
      .callback; // Install callback first to ensure option errors are logged.
  if (options.reset) api.init(); // Reset takes priority.
  callback ??=
      options.callback; // Install callback again in case it has been reset.
  // Only update specified (non-null) options.
  if (options.safeMode != null)
    setOption('safeMode', options.safeMode.toString());
  htmlReplacement ??= options.htmlReplacement;
}

// Set named option value.
setOption(String name, var value) {
  switch (name) {
    case 'safeMode':
      int n = int.tryParse(value);
      if (n == null || n < 0 || n > 15) {
        errorCallback('illegal safeMode API option value: ' + value);
      } else {
        safeMode = n;
      }
      break;
    case 'reset':
      if (value == 'true')
        api.init();
      else if (value != 'false')
        errorCallback('illegal reset API option value: ' + value);
      break;
    case 'htmlReplacement':
      htmlReplacement = value;
      break;
    default:
      errorCallback('illegal API option name: ' + name);
  }
}

// Filter HTML based on current safeMode.
String htmlSafeModeFilter(String html) {
  switch (safeMode & 0x3) {
    case 0: // Raw HTML (default behavior).
      return html;
    case 1: // Drop HTML.
      return '';
    case 2: // Replace HTML with 'htmlReplacement' option string.
      return htmlReplacement;
    case 3: // Render HTML as text.
      return utils.replaceSpecialChars(html);
    default:
      return '';
  }
}

errorCallback(String message) {
  if (callback != null) {
    callback(CallbackMessage('error', message));
  }
}

// Called when an unexpected program error occurs.
panic(String message) {
  String msg = 'panic: ' + message;
  print(msg);
  errorCallback(msg);
}
