import 'dart:io';

class BindgenException implements Exception {
  const BindgenException(this.message);

  const BindgenException.onParse(String message) : this('while parsing: $message');

  BindgenException.onOutput(FileSystemException e) : message = _formatFSE(e);

  final String message;

  @override
  String toString() {
    return 'BindgenException - $message';
  }
}

String _formatFSE(FileSystemException e) {
  var message = StringBuffer()..write('while writing to ${e.path}');
  if (e.osError != null) {
    message.write(': ');
    if (e.osError.message.isNotEmpty) {
      message..write(e.osError.message)..write('. ');
    }
    if (e.osError.errorCode != OSError.noErrorCode) {
      message..write('errno = ')..write(e.osError.errorCode);
    }
  }
  return message.toString();
}
