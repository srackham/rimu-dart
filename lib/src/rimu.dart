/*
 This is the main module, it exports the 'render' API.
 */

import 'api.dart' as api;
import 'options.dart' as options;

///  The single public API which translates Rimu Markup to HTML.
String render(String source, [options.RenderOptions? opts]) {
  opts ??= options.RenderOptions();
  // Lazy first-call API initialisation.
  if (options.safeMode == options.UNDEFINED) {
    api.init();
  }
  options.updateFrom(opts);
  return api.render(source);
}
