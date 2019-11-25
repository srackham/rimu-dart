import 'package:rimu/rimu.dart' as rimu;

main(List<String> arguments) {
  print(rimu.render('Hello *Rimu*!', rimu.RenderOptions(reset: true)));
}
