import 'dart:math' as math;
import 'package:meta/meta.dart';
import 'package:recase/recase.dart';
import 'package:bindgen/src/types.dart';

@sealed
abstract class Declaration {
  const Declaration();
}

class StructDeclaration extends Declaration {
  const StructDeclaration({ @required this.name, @required this.fields });

  factory StructDeclaration.fromJson(Map<String, dynamic> json) {
    return StructDeclaration(
      name: json['name'] as String,
      fields: VariableDeclaration.fromList(json['fields'] as List),
    );
  }

  final String name;
  final List<VariableDeclaration> fields;
}

class EnumDeclaration extends Declaration {
  const EnumDeclaration({
    @required this.name,
    @required this.underlyingType,
    @required this.constants,
  });

  factory EnumDeclaration.fromJson(Map<String, dynamic> json) {
    var name = json['name'] as String;

    return EnumDeclaration(
      name: name,
      underlyingType: getTypeInformation(json['underlying']),
      constants: _castConstants(json['constants'], name),
    );
  }

  final String name;
  final FfiType underlyingType;
  final Map<String, int> constants;

  bool get isSimple {
    var valueSet = Set.of(constants.values);
    return valueSet.length == constants.length &&
      valueSet.reduce(math.min) == 0 &&
      valueSet.reduce(math.max) == constants.length - 1;
  }

  static Map<String, int> _castConstants(dynamic json, String name) {
    var constants = (json as Map).cast<String, int>();
    var isNamespaced = constants.keys.every((constant) {
      return constant.startsWith(name);
    });

    if (!isNamespaced) return constants;

    return constants.map((constant, value) {
      constant = constant.replaceFirst(name, '');
      if (constant.startsWith('_')) constant = constant.substring(1);
      return MapEntry(constant, value);
    });
  }
}

class FunctionDeclaration extends Declaration {
  const FunctionDeclaration({
    @required this.name,
    @required this.returnType,
    @required this.arguments,
    bool variadic,
  }) : _variadic = variadic ?? false;

  factory FunctionDeclaration.fromJson(Map<String, dynamic> json) {
    return FunctionDeclaration(
      name: json['name'] as String,
      returnType: getTypeInformation(json['returns']),
      arguments: VariableDeclaration.fromList(json['args'] as List),
      variadic: json['variadic'] == null ? null : json['variadic'] as bool,
    );
  }

  final String name;
  final FfiType returnType;
  final List<VariableDeclaration> arguments;
  final bool _variadic;

  bool get isVariadic => _variadic && arguments.isNotEmpty;
  _Typedef get typedef => _Typedef.ofFunction(this);
}

class VariableDeclaration extends Declaration {
  const VariableDeclaration({ @required this.name, @required this.type });

  factory VariableDeclaration.fromJson(Map<String, dynamic> json) {
    return VariableDeclaration(
      name: json['name'] as String,
      type: getTypeInformation(json['type']),
    );
  }

  static List<VariableDeclaration> fromList(List list) {
    return list.map((e) => VariableDeclaration.fromJson(e as Map<String, dynamic>)).toList();
  }

  final String name;
  final FfiType type;

  String get dartRepresentation => '${type.dartRepresentation} $name';
}

class _Typedef {
  _Typedef._(this.nativeName, this.dartName, this.native, this.dart);

  factory _Typedef.ofFunction(FunctionDeclaration decl) {
    var nativeArgs = decl.arguments.map((arg) => '${arg.type.native} ${arg.name}').join(', ');
    var dartArgs = decl.arguments.map((arg) => '${arg.type.dart} ${arg.name}').join(', ');
    var nativeTypedef = '${decl.returnType.native} Function(${nativeArgs})';
    var dartTypedef = '${decl.returnType.dart} Function(${dartArgs})';

    return _Typedef._('_${decl.name}_func', '_${decl.name.pascalCase}', nativeTypedef, dartTypedef);
  }

  final String nativeName;
  final String dartName;
  final String native;
  final String dart;
}
