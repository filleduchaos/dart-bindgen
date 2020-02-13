import 'dart:async';
import 'dart:io' show Process, Directory;
import 'dart:mirrors';
import 'package:path/path.dart' as p;

IsolateMirror _isolate;

String _testDir;

String get testDir {
  _testDir ??= p.dirname(_sourceUri.toFilePath());
  return _testDir;
}
String get e2eSourceDir => p.join(testDir, 'fixtures/src');
String get e2eBuildDir => p.join(testDir, 'fixtures/build');
String get e2eLibDir => p.join(testDir, 'fixtures/lib');
String get e2eTempDir => p.join(testDir, 'e2e/tmp');

Uri get _sourceUri => (reflect(buildLib) as ClosureMirror).function.location.sourceUri;

void buildLib(String name) {
  if (!Directory(e2eBuildDir).existsSync()) _cmake();

  var make = Process.runSync('make', [name], workingDirectory: e2eBuildDir);
  if (make.exitCode != 0) throw 'Failed to build $name';

  var install = Process.runSync('make', ['install'], workingDirectory: e2eBuildDir);
  if (install.exitCode != 0) throw 'Failed to install $name';
}

Future<void> bindgenCli(List<String> arguments) async {
  var bindgen = p.join(testDir, '../bin/bindgen.dart');
  final cliProcess = await Process.run('dart', [bindgen, ...arguments], environment: {
    'DART_BINDGEN_DIR': p.join(testDir, '../../build'), 
  });
  if (cliProcess.exitCode != 0) {
    throw cliProcess.stdout;
  }
}

Future<LibraryMirror> loadDart(String dartFilePath) {
  _isolate ??= currentMirrorSystem().isolate;
  return _isolate.loadUri(Uri.file(dartFilePath));
}

void _cmake() {
  Directory(e2eBuildDir).createSync();
  var cmake = Process.runSync('cmake', ['-S', '..'], workingDirectory: e2eBuildDir);
  if (cmake.exitCode != 0) throw 'Failed to run cmake';
}
