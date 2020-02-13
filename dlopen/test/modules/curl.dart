import 'dart:ffi';
import 'package:test/test.dart';

typedef _CurlEasyInit = Pointer Function();

typedef _curl_easy_cleanup = Void Function(Pointer);
typedef _CurlEasyCleanup = void Function(Pointer);

const CURLE_OK = 0;

class LibCurl {
  static void test(DynamicLibrary lib) {
    var curlEasyInit = lib.lookupFunction<_CurlEasyInit, _CurlEasyInit>('curl_easy_init');
    var curlEasyCleanup = lib.lookupFunction<_curl_easy_cleanup, _CurlEasyCleanup>('curl_easy_cleanup');

    var curl = curlEasyInit();
    expect(curl, isNot(equals(nullptr)));
    curlEasyCleanup(curl);
  }
}
