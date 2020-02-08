import 'dart:io';
import 'package:bindgen/bindgen.dart';
import 'package:bindgen/loaders.dart';

void main(List<String> arguments) async {
  exitCode = 0;

  var args = Bindgen.parseArguments(arguments);
  if (args['help'] == true) {
    print(Bindgen.helpText);
  }
  else {
    try {
      Loader.register('clang', const ClangLoader());

      var bindgen = Bindgen.fromArguments(args);
      await bindgen.run();
    }
    catch (e, st) {
      print(e);
      if (e is BindgenException) exit(1);

      print(st);
      exit(2);
    }
  }

}
