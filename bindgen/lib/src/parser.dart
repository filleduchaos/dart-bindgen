import 'dart:convert';
import 'package:bindgen/src/exception.dart';
import 'package:bindgen/src/declaration.dart';

class Parser {
  const Parser({ this.verbose = false });

  final bool verbose;

  String _getMessage(String message, dynamic item) {
    if (verbose) {
      message += '\nJSON dump:\n';
      var encoder = JsonEncoder.withIndent('  ');
      message += encoder.convert(item);
    }
    return message;
  }

  Declaration _buildDeclaration(Map<String, dynamic> json) {
    var type = json['type'];
    switch (type) {
      case 'function':
        return FunctionDeclaration.fromJson(json);
      case 'struct':
        return StructDeclaration.fromJson(json);
      case 'enum':
        return EnumDeclaration.fromJson(json);
      default:
        var message = _getMessage('unsupported top-level declaration type $type', json);
        throw BindgenException.onParse(message);
    }
  }

  List<Declaration> call(List json) {
    try {
      return json.cast<Map<String, dynamic>>().map(_buildDeclaration).toList();
    }
    on CastError {
      var message = _getMessage('unable to parse the loaded library.', json);
      throw BindgenException.onParse(message);
    }
  }
}
