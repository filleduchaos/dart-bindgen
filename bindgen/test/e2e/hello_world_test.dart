import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:bindgen/src/code_buffer.dart';
import '../test_helper.dart';
import 'generated_library.dart';

void main() {
  var libHello = GeneratedLibrary('hello');

  group('hello_world', () {
    String mainPath;

    setUpAll(() async {
      await libHello.build('libhello.dart');
      mainPath = p.join(libHello.dir, 'hello.dart');

      var helloTest = CodeBuffer()
        ..addImport('libhello.dart')
        ..addLine()
        ..addFunction('main', builder: (buf) {
          buf.addLine("LibHello.\$open.addSearchPath('${e2eLibDir}');");
          buf.addLine('var hello = LibHello();');
          buf.addLine('hello.helloWorld();');
        });
      await File(mainPath).writeAsString(helloTest.toString(), flush: true);
    });

    tearDownAll(libHello.release);

    test("prints 'Hello World' to stdout", () async {
      var testProcess = await Process.run('dart', [mainPath]);

      expect(testProcess.stderr, isEmpty);
      expect(testProcess.exitCode, equals(0));
      expect(testProcess.stdout, equals('Hello World\n'));
    });
  }, skip: !isE2E);
}
