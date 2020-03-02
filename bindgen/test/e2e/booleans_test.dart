import 'package:test/test.dart';
import 'generated_library.dart';
import '../test_helper.dart' show isE2E;

void main() {
  var libBool = GeneratedLibrary('booleans');

  group('booleans', () {
    setUpAll(() async {
      await libBool.build();
      await libBool.load();
    });

    tearDownAll(libBool.release);

    test('#isPrime checks if a number is prime', () {
      var result = libBool.call('isPrime', [2]);
      expect(result, isA<bool>());
      expect(result, isTrue);

      var primeChecker = (int number) => libBool.call('isPrime', [number]) as bool;
      expect([3889, 4919, 223, 9803, 4519, 2593, 4877].every(primeChecker), isTrue);
      expect([8383, 7872, 1003, 5255, 6686, 1203, 4480].any(primeChecker), isFalse);
    });

    test('#greetDoctor changes behaviour based on a flag', () {
      var name = 'Akira';

      expect(libBool.call('greetDoctor', [name, false]), equals('Hello, Akira'));
      expect(libBool.call('greetDoctor', [name, true]), equals('Hello, Dr. Akira'));
    });
  }, skip: !isE2E);
}
