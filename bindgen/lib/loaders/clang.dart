import 'dart:convert';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:dlopen/dlopen.dart';
import 'package:bindgen/loaders/loader.dart';
import 'package:bindgen/src/helpers.dart';

typedef _walk_clang_ast_func = ffi.Pointer<TraversalResult> Function(ffi.Pointer<Utf8>);
typedef _WalkClangAst = ffi.Pointer<TraversalResult> Function(ffi.Pointer<Utf8>);

class TraversalResult extends ffi.Struct {
  @ffi.Int32()
  int status;

  ffi.Pointer<Utf8> data;

  String unwrap() {
    var result = data.unwrap();
    if (status == 0) return result;

    throw result;
  }
}

class ClangLoader extends Loader {
  static get _dlopen => DlOpen(searchPaths: Dir.loaderSearchPaths);
  static ffi.DynamicLibrary _lib;
  static _WalkClangAst _walkClangAst;

  const ClangLoader();

  @override
  void init() {
    _lib ??= _dlopen('clang_bindgen_plugin', includeSystem: false);
    _walkClangAst ??= _lib.lookupFunction<_walk_clang_ast_func, _WalkClangAst>('walk_clang_ast');
  }

  @override
  call(String path) async {
    var filename = Utf8.toUtf8(path);
    var resultPtr = _walkClangAst(filename);
    var result = resultPtr.ref.unwrap();

    return json.decode(result) as List;
  }
}
