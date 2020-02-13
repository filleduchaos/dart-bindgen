@TestOn('mac-os || linux')

import 'dart:ffi';
import 'dart:io' show Directory;

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:dlopen/dlopen.dart';
import 'package:glob/glob.dart';

import 'test_helper.dart';
import 'modules/crypto.dart';
import 'modules/curl.dart';

var throwsDlOpenException = throwsA(isA<DlOpenException>());

void main() {
  setUp(() {
    Directory(p.join(testDir, 'fixtures/lib')).createSync();
  });

  tearDown(() {
    dlOpen.reset();
    Directory(p.join(testDir, 'fixtures/lib')).deleteSync(recursive: true);
  });

  tearDownAll(() async {
    await Glob(p.join(testDir, 'fixtures/*.o')).list().forEach((file) {
      file.delete();
    });
  });

  group('dlclose', () {
    var dlErrorMatcher = (String error) => allOf(isArgumentError, predicate((e) => e.toString().contains(error)));

    test('closes opened lib successfully', () {
      buildStubLib('crypto', 'crypto.out');

      var crypto = DynamicLibrary.open(p.join(testDir, 'fixtures/lib/crypto.out'));
      LibCrypto.test(crypto);
      dlClose(crypto);
      expect(() => LibCrypto.test(crypto), throwsA(dlErrorMatcher('Failed to lookup symbol')));
    });

    test('throws an error if lib is closed twice', () {
      buildStubLib('crypto', 'crypto.out');

      var crypto = DynamicLibrary.open(p.join(testDir, 'fixtures/lib/crypto.out'));
      LibCrypto.test(crypto);
      dlClose(crypto);
      expect(() => dlClose(crypto), throwsA(dlErrorMatcher('Unable to close the passed library')));
    });
  });

  group('dlopen', () {
    test('finds and opens installed lib by name', () {
      var crypto = dlOpen('crypto');
      LibCrypto.test(crypto);
      dlClose(crypto);

      var curl = dlOpen('curl');
      LibCurl.test(curl);
      dlClose(curl);
    });

    test('does not find installed lib if system libs are excluded', () {
      for (var name in ['crypto', 'curl']) {
        expect(() => dlOpen(name, includeSystem: false), throwsDlOpenException);
      }
    });

    test('finds libs given a search path', () {
      buildStubLib('crypto');
      dlOpen.addSearchPath(p.join(testDir, 'fixtures/lib'));
      var crypto = dlOpen('crypto', includeSystem: false);
      LibCrypto.test(crypto);
      dlClose(crypto);
    });

    test('can open libraries by specific version', () {
      buildStubLib('crypto', 'libcrypto.1.12');
      dlOpen.addSearchPath(p.join(testDir, 'fixtures/lib'));

      expect(() => dlOpen('crypto', includeSystem: false), throwsDlOpenException);

      var crypto = dlOpen('crypto', version: '1.12', includeSystem: false);
      LibCrypto.test(crypto);
      dlClose(crypto);

      expect(() => dlOpen('crypto', version: '1.15', includeSystem: false), throwsDlOpenException);
    });

    test('can override open implementation', () {
      buildStubLib('crypto', 'crypto.out');
      dlOpen.override((name, _, __) {
        return DynamicLibrary.open(p.join(testDir, 'fixtures/lib/$name.out'));
      });

      var crypto = dlOpen('crypto', includeSystem: false);
      LibCrypto.test(crypto);
      dlClose(crypto);
    });
  });
}
