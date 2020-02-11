@TestOn('mac-os && linux')

import 'package:test/test.dart';
import 'package:dlopen/dlopen.dart';

import 'modules/crypto.dart';

void main() {
  group('dlopen', () {
    test('finds and opens installed lib by name', () {
      var lib = dlopen('crypto');
      LibCrypto.test(lib);
    });

    test('does not find installed lib if system libs are excluded', () {
      var throwsDlOpenException = throwsA(isA<DlOpenException>());
      expect(() => dlopen('crypto', includeSystem: false), throwsDlOpenException);
    });

    test('finds lib with specified path', () {
      dlopen.addSearchPath('/usr/lib');
      var lib = dlopen('crypto', includeSystem: false);
      LibCrypto.test(lib);
    });
  });
}
