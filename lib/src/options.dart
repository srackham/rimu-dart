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

typedef CallbackFunction = Function(CallbackMessage);

// Global option values.
int safeMode;
String htmlReplacement;
CallbackFunction callback;

// Reset options to default values.
void init() {
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
  return safeMode & 0x4 != 0;
}

// Return true if Macro Definitions are ignored.
bool skipMacroDefs() {
  return safeMode != 0 && safeMode & 0x8 == 0;
}

// Update specified (non-null) options.
void updateOptions(RenderOptions options) {
  // Install callback first to ensure option errors are logged.
  if (options.callback != null) {
    callback = options.callback;
  }
  setOption('reset', options.reset); // Reset takes priority.
  // Install callback again in case it has been reset.
  if (options.callback != null) {
    callback = options.callback;
  }
  if (options.safeMode != null) {
    setOption('safeMode', options.safeMode.toString());
  }
  if (options.htmlReplacement != null) {
    setOption('htmlReplacement', options.htmlReplacement);
  }
}

// Set named option value.
void setOption(String name, var value) {
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
      if (value == null || value == false || value == 'false') {
        return;
      } else if (value == true || value == 'true') {
        api.init();
      } else {
        errorCallback('illegal reset API option value: ' + value);
      }
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

void errorCallback(String message) {
  if (callback != null) {
    callback(CallbackMessage('error', message));
  }
}

// Called when an unexpected program error occurs.
void panic(String message) {
  String msg = 'panic: ' + message;
  print(msg);
  errorCallback(msg);
}
