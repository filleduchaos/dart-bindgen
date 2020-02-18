import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:test/test.dart';
import 'generated_library.dart';
import '../test_helper.dart' show isE2E, WithIndex;

void main() {
  var libEnums = GeneratedLibrary('enums');

  group('enums', () {
    setUpAll(() async {
      await libEnums.build();
      await libEnums.load();
    });

    tearDownAll(libEnums.release);

    test('Color is a basic enum', () {
      var Color = libEnums.findEnum('Color');
      var members = ['red', 'orange', 'yellow', 'green', 'blue', 'indigo', 'violet'];
      members.eachWithIndex((member, index) {
        expect(GeneratedLibrary.getEnumValue(Color, member), equals(index));
      });
    });

    test('Namespaced is a namespaced basic enum', () {
      var Namespaced = libEnums.findEnum('Namespaced');
      var members = ['foo', 'bar', 'baz', 'quuz'];
      members.eachWithIndex((member, index) {
        expect(GeneratedLibrary.getEnumValue(Namespaced, member), equals(index));
      });
    });
  }, skip: !isE2E);
}
