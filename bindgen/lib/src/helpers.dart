import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

extension UnwrapStrings on Pointer<Utf8> {
  String unwrap() {
    return Utf8.fromUtf8(this);
  }
}

abstract class Dir {
  static List<String> get loaderSearchPaths {
    var searchPaths = <String>[];
    var folder = Platform.environment['DART_BINDGEN_DIR'];
    if (folder != null) {
      searchPaths.add(folder);
    }
    else {
      try {
        // For development only, might fail in other environments
        searchPaths.add(build());
      } catch (e) { /* */ }
      var home = Platform.environment['HOME'] ?? Platform.environment['APPDATA'];
      searchPaths.add(path.join(home, '.dart_bindgen'));
    }
    return searchPaths.map((p) => path.join(p, 'lib')).toList();
  }

  static String build() {
    return path.join(path.dirname(Platform.script.toFilePath()), '../../build');
  }

  static String resource([ String filePath = '' ]) {
    var folder = Platform.environment['DART_BINDGEN_DIR'];
    if (folder == null) {
      var home = Platform.environment['HOME'] ?? Platform.environment['APPDATA'];
      folder = path.join(home, '.dart_bindgen');
    }
    return path.join(path.absolute(folder, filePath));
  }
}

int hashAll(Iterable items) {
  var hash = items.fold(0, _foldHash);
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}

int _foldHash(int hash, dynamic item) {
  hash = 0x1fffffff & (hash + item.hashCode);
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}
