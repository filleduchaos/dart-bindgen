import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import '../test_helper.dart';
import 'package:bindgen/src/code_buffer.dart';

void main() {
  Directory tempDir;

  setUpAll(() {
    buildLib('hello');
    tempDir = Directory(e2eTempDir)..createSync()..createTempSync();
  });

  tearDownAll(() {
    tempDir?.deleteSync(recursive: true);
    Directory(e2eBuildDir).deleteSync(recursive: true);
    Directory(e2eLibDir).deleteSync(recursive: true);
  });

  group('hello_world', () {
    String inPath, outPath, mainPath;

    setUp(() async {
      inPath = p.join(e2eSourceDir, 'hello.h');
      outPath = p.join(tempDir.path, 'libhello.dart');
      mainPath = p.join(tempDir.path, 'hello.dart');

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

    test("prints 'Hello World' to stdout", () async {
      await bindgenCli(['-o', outPath, inPath]);

      expect(await File(outPath).exists(), true);

      var testProcess = await Process.run('dart', [mainPath]);

      expect(testProcess.stderr, isEmpty);
      expect(testProcess.exitCode, equals(0));
      expect(testProcess.stdout, equals('Hello World\n'));
    });
  });
}
