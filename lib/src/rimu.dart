/*
 This is the main module, it exports the 'render' API.
 */

import 'api.dart' as api;
import 'options.dart' as options;

///  The single public API which translates Rimu Markup to HTML.
String render(String source, [options.RenderOptions opts]) {
  opts ??= options.RenderOptions();
  // Implicit first-call API initialisation.
  if (options.safeMode == null) {
    api.init();
  }
  options.updateFrom(opts);
  return api.render(source);
}
