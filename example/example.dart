import 'package:rimu/rimu.dart' show RenderOptions, render;

void main(List<String> arguments) {
  print(render('Hello *Rimu*!', RenderOptions(reset: true)));
}
