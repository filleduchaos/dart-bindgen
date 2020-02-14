import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:test/test.dart';
import 'generated_library.dart';
import '../test_helper.dart' show isE2E;

void main() {
  var libPrimitives = GeneratedLibrary('primitives');

  group('primitives', () {
    setUpAll(() async {
      await libPrimitives.build();
      await libPrimitives.load();
    });

    tearDownAll(libPrimitives.release);

    test('#sum adds two numbers', () {
      var result = libPrimitives.call('sum', [13, 21]);
      
      expect(result, isA<int>());
      expect(result, equals(34));
    });

    test('#subtract subtracts a referenced number and a number', () {
      var a = allocate<Int32>();
      a.value = 34;

      var result = libPrimitives.call('subtract', [a, 21]);

      expect(result, isA<int>());
      expect(result, equals(13));
    });

    test('#multiply multiplies two numbers and returns a pointer', () {
      var result = libPrimitives.call('multiply', [6, 36]);

      expect(result, isA<Pointer<Int32>>());
      expect((result as Pointer<Int32>).value, equals(216));
    });

    test('#multiSum', () {

    }, skip: 'primitives #multiSum is pending proper implementation of variadic functions');
  }, skip: !isE2E);
}
