import 'dart:ffi';

typedef NativeVoidFunction = Void Function();
typedef VoidFunction = void Function();

class LibCrypto {
  static void test(DynamicLibrary lib) {
    var loadStrings = lib.lookupFunction<NativeVoidFunction, VoidFunction>('ERR_load_crypto_strings');
    var freeStrings = lib.lookupFunction<NativeVoidFunction, VoidFunction>('ERR_free_strings');

    loadStrings();
    freeStrings();
  }
}
