import 'dart:io';
import 'dart:ffi';

DynamicLibrary _stdlib;
_DlClose _dlclose;

typedef _DlClose = int Function(Pointer);

void dlClose(DynamicLibrary lib) {
  if (_dlclose == null) {
    _stdlib ??= Platform.isWindows ? DynamicLibrary.open('kernel32.dll') : DynamicLibrary.process();
    var dlclose_name = Platform.isWindows ? 'FreeLibrary' : 'dlclose';
    _dlclose = _stdlib.lookupFunction<Int32 Function(Pointer), _DlClose>(dlclose_name);
  }

  var result = _dlclose(lib.handle);
  // Thanks, Bill
  if ((result == 0) ^ Platform.isWindows) return;

  // TODO: Get more specific error?
  throw ArgumentError('Unable to close the passed library.');
}
