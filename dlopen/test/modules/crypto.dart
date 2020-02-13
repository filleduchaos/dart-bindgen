import 'dart:ffi';

typedef _NativeVoidFunction = Void Function();
typedef _VoidFunction = void Function();

class LibCrypto {
  static void test(DynamicLibrary lib) {
    var loadStrings = lib.lookupFunction<_NativeVoidFunction, _VoidFunction>('ERR_load_crypto_strings');
    var freeStrings = lib.lookupFunction<_NativeVoidFunction, _VoidFunction>('ERR_free_strings');

    loadStrings();
    freeStrings();
  }
}
