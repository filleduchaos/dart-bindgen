import 'dart:io';
import 'dart:mirrors';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import '../test_helper.dart';

void main() {
  Directory tempDir;
  String generated;

  setUpAll(() async {
    buildLib('primitives');
    tempDir = (Directory(e2eTempDir)..createSync()).createTempSync();

    var header = p.join(e2eSourceDir, 'primitives.h');
    generated = p.join(tempDir.path, 'primitives.dart');

    await bindgenCli(['-o', generated, header]);
  });

  tearDownAll(() {
    tempDir?.deleteSync(recursive: true);
    Directory(e2eBuildDir).deleteSync(recursive: true);
    Directory(e2eLibDir).deleteSync(recursive: true);
  });

  group('primitives', () {
    InstanceMirror libPrimitives;

    setUpAll(() async {
      var lib = await loadDart(generated);
      var LibPrimitivesClass = lib.declarations[Symbol('LibPrimitives')] as ClassMirror;

      var libPrimitivesOpen = LibPrimitivesClass.getField(Symbol('\$open'));
      libPrimitivesOpen.invoke(Symbol('addSearchPath'), [e2eLibDir]);

      libPrimitives = LibPrimitivesClass.newInstance(Symbol(''), []);
    });

    test('#sum adds two numbers', () {
      var result = libPrimitives.invoke(Symbol('sum'), [13, 21]).reflectee;
      
      expect(result, isA<int>());
      expect(result, equals(34));
    });

    test('#subtract subtracts a referenced number and a number', () {
      var a = allocate<Int32>();
      a.value = 34;

      var result = libPrimitives.invoke(Symbol('subtract'), [a, 21]).reflectee;

      expect(result, isA<int>());
      expect(result, equals(13));
    });

    test('#multiply multiplies two numbers and returns a pointer', () {
      var result = libPrimitives.invoke(Symbol('multiply'), [6, 36]).reflectee;

      expect(result, isA<Pointer<Int32>>());
      expect((result as Pointer<Int32>).value, equals(216));
    });

    test('#multiSum', () {

    }, skip: 'primitives #multiSum is pending proper implementation of variadic functions');
  });
}
