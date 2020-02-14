import 'dart:io' show Process, Platform;
import 'dart:mirrors';
import 'package:path/path.dart' as p;

String cc;
String _testDir;

String get testDir {
  _testDir ??= p.dirname(_sourceUri.toFilePath());
  return _testDir;
}

Uri get _sourceUri => (reflect(buildStubLib) as ClosureMirror).function.location.sourceUri;

void buildStubLib(String name, [ String outName ]) {
  cc ??= _findCCompiler();
  var ext = Platform.isMacOS ? '.dylib' : '.so';
  outName ??= 'lib$name$ext';
  if (double.tryParse(p.extension(outName)) != null) {
    outName += ext;
  };
  _compileAndLink(name, outName);
}

String _findCCompiler() {
  for (var compiler in ['clang', 'gcc']) {
    var result = Process.runSync('command', ['-v', compiler, '>/dev/null', '2>&1']);
    if (result.exitCode == 0) return compiler;
  }

  throw 'Unable to find a C compiler; please ensure one is installed';
}

void _compileAndLink(String name, String outName) {
  var result = Process.runSync(cc, ['$testDir/fixtures/$name.c', '-c', '-fpic', '-o', '$testDir/fixtures/$name.o']);
  if (result.exitCode != 0) throw 'An error occurred while compiling stub library $name';

  result = Process.runSync(cc, ['$testDir/fixtures/$name.o', '-shared', '-o', '$testDir/fixtures/lib/$outName']);
  if (result.exitCode != 0) throw 'An error occurred while linking stub library $name';
}
