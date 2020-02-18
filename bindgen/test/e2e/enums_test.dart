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
      members.eachWithIndex(_testMembers(Color));
    });

    test('Namespaced is a namespaced basic enum', () {
      var Namespaced = libEnums.findEnum('Namespaced');
      var members = ['foo', 'bar', 'baz', 'quuz'];
      members.eachWithIndex(_testMembers(Namespaced));
    });

    test('DataType is a complex enum', () {
      var DataType = libEnums.findClass('DataType');
      var members = {
        'Char': 8,
        'Short': 16,
        'Int': 32,
        'Long': 64,
      };
      members.forEach(_testMembers(DataType));
    });

    test('NetWorth is a complex enum with Long values', () {
      var NetWorth = libEnums.findClass('NetWorth');
      var members = {
        'thousand': 1000,
        'million': 1000 * 1000,
        'billion': 1000 * 1000 * 1000,
        'trillion': 1000 * 1000 * 1000 * 1000,
      };
      members.forEach(_testMembers(NetWorth));
    });

    test('Status is a complex enum with negative values', () {
      var Status = libEnums.findClass('Status');
      var members = {
        'error': -2,
        'success': 0,
        'warning': -1,
      };
      members.forEach(_testMembers(Status));
    });
  }, skip: !isE2E);
}

void Function(String, int) _testMembers(ClassMirror Enum) => (member, value) {
  expect(GeneratedLibrary.getEnumValue(Enum, member), equals(value));
};
