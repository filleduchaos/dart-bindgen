import 'package:test/test.dart';
import 'generated_library.dart';
import '../test_helper.dart' show isE2E, WithIndex;

void main() {
  var libEnums = GeneratedLibrary('enums');

  void Function(String, int) _testFunctionCalling(ClassMirror Enum, String testFunc) {
    return (member, result) {
      var constant = GeneratedLibrary.getEnumConstant(Enum, member);
      expect(libEnums.call(testFunc, [constant]), equals(result));
    };
  }

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

      ({
        for (var m in members) m: m == 'green' ? 1 : 0,
      }).forEach(_testFunctionCalling(Color, 'isGreen'));

      var redWavelength = 680;
      var blueWavelength = 500;

      expect(libEnums.call('getColor', [redWavelength]), equals(GeneratedLibrary.getEnumConstant(Color, 'red')));
      expect(libEnums.call('getColor', [blueWavelength]), equals(GeneratedLibrary.getEnumConstant(Color, 'blue')));
    });

    test('Namespaced is a namespaced basic enum', () {
      var Namespaced = libEnums.findEnum('Namespaced');
      var members = ['foo', 'bar', 'baz', 'quuz'];
      members.eachWithIndex(_testMembers(Namespaced));

      ({
        for (var m in members) m: m == 'foo' ? 1 : 0,
      }).forEach(_testFunctionCalling(Namespaced, 'isFoo'));
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
      members
        .map((k, v) => MapEntry(k, v > 24 ? 1 : 0))
        .forEach(_testFunctionCalling(DataType, 'canHold24Bits'));
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
      members
        .map((k, v) => MapEntry(k, k == 'billion' ? 1 : 0))
        .forEach(_testFunctionCalling(NetWorth, 'isBillionaire'));
    });

    test('Status is a complex enum with negative values', () {
      var Status = libEnums.findClass('Status');
      var members = {
        'error': -2,
        'success': 0,
        'warning': -1,
      };
      members.forEach(_testMembers(Status));
      members
        .map((k, v) => MapEntry(k, k == 'success' ? 0 : 1))
        .forEach(_testFunctionCalling(Status, 'failed'));
    });
  }, skip: !isE2E);
}

void Function(String, int) _testMembers(ClassMirror Enum) => (member, value) {
  expect(GeneratedLibrary.getEnumConstantValue(Enum, member), equals(value));
};
