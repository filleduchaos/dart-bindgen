import 'dart:io';
import 'dart:ffi' show Struct;
import 'dart:mirrors';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart' show StringReCase;
import '../test_helper.dart';

final StructMirror = reflectType(Struct);

class GeneratedLibrary {
  GeneratedLibrary(this.name);

  final String name;

  Directory _dir;
  String get dir => _dir.path;

  String _path;
  String get path => _path ??= p.join(_dir.path, '$name.dart');

  LibraryMirror _lib;
  InstanceMirror _functions;

  Future<void> build([String outPath]) async {
    _dir = (Directory(e2eTempDir)..createSync()).createTempSync();
    if (outPath != null) _path = p.join(_dir.path, outPath);
    var header = p.join(e2eSourceDir, '$name.h');

    buildLib(name);
    await bindgenCli(['-o', path, header]);
    assert(await File(_path).exists());
  }

  Future<void> load() async {
    _lib = await loadDart(path);

    var LibClass = _getClass('Lib${name.pascalCase}');
    _functions = LibClass.newInstance(Symbol(''), []);

    var libOpen = LibClass.getField(Symbol('\$open'));
    libOpen.invoke(Symbol('addSearchPath'), [e2eLibDir]);
  }

  dynamic call(String name, [List arguments = const []]) {
    return _functions.invoke(Symbol(name), arguments).reflectee;
  }

  Type findStruct(String name) {
    var StructClass = _getClass(name);
    assert(StructClass.isSubtypeOf(StructMirror));
    return StructClass.reflectedType;
  }

  Future<void> release() async {
    try {
      _dir?.deleteSync(recursive: true);
      Directory(e2eBuildDir).deleteSync(recursive: true);
      Directory(e2eLibDir).deleteSync(recursive: true);
    }
    on FileSystemException catch (e) {
      if (e.osError?.message?.contains('No such file or directory') ?? false) {}
      else { rethrow; };
    }
  }

  ClassMirror _getClass(String name) {
    var declaration = _lib.declarations[Symbol(name)];
    assert(declaration != null);
    return declaration as ClassMirror;
  }
}