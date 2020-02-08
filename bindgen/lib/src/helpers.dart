import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;
import 'package:bindgen/src/exception.dart';

extension UnwrapStrings on Pointer<Utf8> {
  String unwrap() {
    return Utf8.fromUtf8(this);
  }
}

abstract class Dir {
  static String build([ String filePath = '' ]) {
    return path.join(path.dirname(Platform.script.toFilePath()), '../../build', filePath);
  }

  static String data([ String filePath = '' ]) {
    var folder = Platform.environment['DART_BINDGEN_DIR'];
    if (folder == null) {
      var home = Platform.environment['HOME'] ?? Platform.environment['APPDATA'];
      folder = path.join(home, '.dart_bindgen');
    }
    return path.join(path.absolute(folder, filePath));
  }
}

String _getPlatformName(String name) {
  var extension = '.so';
  if (Platform.isWindows) {
    extension = '.dll';
  } else {
    name = 'lib$name';
  }
  if (Platform.isIOS || Platform.isMacOS) extension = '.dylib';

  return name + extension;
}

DynamicLibrary dlopen(String name, { List<String> folders }) {
  folders ??= [];
  folders.insert(0, '');

  var platformName = _getPlatformName(name);

  DynamicLibrary lib;
  var errors = [];

  for (var folder in folders) {
    try {
      lib = DynamicLibrary.open(path.join(folder, platformName));
      break;
    }
    catch (e) { errors.add(e); }
  }
  
  if (lib != null) return lib;

  var errorMsg = StringBuffer()..writeln('error opening library $name');
  errorMsg.writeAll(errors, '\n');
  throw BindgenException(errorMsg.toString());
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
