import 'dart:ffi';
import 'dart:io' show Platform;
import 'package:path/path.dart' as p;
import 'package:dlopen/src/exception.dart';

enum OS {
  android,
  fuchsia,
  iOS,
  linux,
  macOS,
  windows,
}

OS get _os {
  if (Platform.isAndroid) return OS.android;
  if (Platform.isFuchsia) return OS.fuchsia;
  if (Platform.isIOS) return OS.iOS;
  if (Platform.isLinux) return OS.linux;
  if (Platform.isMacOS) return OS.macOS;
  if (Platform.isWindows) return OS.windows;
  return null;
}

typedef DlOpener = DynamicLibrary Function(String name, String version, bool includeSystem);

String _dlExtension() {
  if (Platform.isWindows) return 'dll';
  if (Platform.isIOS || Platform.isMacOS) return 'dylib';

  return 'so';
}

String _getSoName(String name, String version) {
  var sb = StringBuffer();
  if (!Platform.isWindows) sb.write('lib');
  sb.write(name);
  if (version.isNotEmpty) sb..write('.')..write(version);
  sb..write('.')..write(_dlExtension());

  return sb.toString();
}


class DlOpen {
  DlOpen({ Iterable<String> searchPaths }) : _searchPaths = Set.from(searchPaths ?? {});

  final Map<OS, DlOpener> _osOverrides = {};
  DlOpener _override;
  final Set<String> _searchPaths;

  DynamicLibrary call(String name, {
    String version = '',
    bool includeSystem = true,
  }) {
    if (_override != null) return _override(name, version, includeSystem);
    
    var osOverride = _osOverrides[_os];
    if (osOverride != null) return osOverride(name, version, includeSystem);

    return open(name, version, includeSystem);
  }

  DynamicLibrary open(String libraryName, String version, bool includeSystem) {
    var soname = _getSoName(libraryName, version);
    var names = _searchPaths.map((path) => p.join(path, soname)).toList();
    if (includeSystem) names.add(soname);

    DynamicLibrary lib;
    var errors = <String>[];

    for (var name in names) {
      try {
        lib = DynamicLibrary.open(name);
        break;
      }
      on ArgumentError catch (e) { errors.add(e.message); }
    }

    if (lib != null) return lib;

    throw DlOpenException(libraryName, version: version, originalErrors: errors);
  }

  void addSearchPath(String path) {
    assert(path != null);
    _searchPaths.add(path);
  }

  void removeSearchPath(String path) => _searchPaths.remove(path);

  void operator []=(OS system, DlOpener opener) {
    assert(system != null && opener != null);
    _osOverrides[system] = opener;
  }

  void override(DlOpener opener) {
    assert(opener != null);
    _override = opener;
  }

  void reset() {
    _override = null;
    _osOverrides.clear();
    _searchPaths.clear();
  }
}
