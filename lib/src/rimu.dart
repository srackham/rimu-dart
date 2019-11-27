/*
 This is the main module, it exports the 'render' API.

 The compiled modules are bundled by Webpack into 'var' (script tag) and 'commonjs' (npm)
 formatted libraries.
 */

import 'api.dart' as api;
import 'options.dart' as options;

// export {RenderOptions as Options, CallbackMessage, CallbackFunction} from './options'

///  The single public API which translates Rimu Markup to HTML.
String render(String source, [options.RenderOptions opts]) {
  opts ??= options.RenderOptions();
  // options.updateOptions(opts);
  return api.render(source);
}

// Load-time initialization.
// api.init();
