import 'dart:collection';
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
    @required this.size,
    @required this.constants,
  });

  factory EnumDeclaration.fromJson(Map<String, dynamic> json) {
    var size = getTypeInformation(json['size']);
    var constants = (json['constants'] as Map).cast<String, int>();

    return EnumDeclaration(
      name: json['name'] as String,
      size: size,
      constants: SplayTreeMap.from(constants, (key1, key2) {
        return constants[key1].compareTo(constants[key2]);
      }),
    );
  }

  final String name;
  final FfiType size;
  final SplayTreeMap<String, int> constants;
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
  const VariableDeclaration({ @required this.name, @required this.type, this.value });

  factory VariableDeclaration.fromJson(Map<String, dynamic> json) {
    return VariableDeclaration(
      name: json['name'] as String,
      type: getTypeInformation(json['type']),
      value: json['value'],
    );
  }

  static List<VariableDeclaration> fromList(List list) {
    return list.map((e) => VariableDeclaration.fromJson(e as Map<String, dynamic>)).toList();
  }

  final String name;
  final FfiType type;
  final dynamic value;

  String get inNative => '${type.native} $name';
  String get inDart => '${type.dart} $name';
}

class _Typedef {
  _Typedef._(this.nativeName, this.dartName, this.native, this.dart);

  factory _Typedef.ofFunction(FunctionDeclaration decl) {
    var nativeArgs = decl.arguments.map((arg) => arg.inNative).join(', ');
    var dartArgs = decl.arguments.map((arg) => arg.inDart).join(', ');
    var nativeTypedef = '${decl.returnType.native} Function(${nativeArgs})';
    var dartTypedef = '${decl.returnType.dart} Function(${dartArgs})';

    return _Typedef._('_${decl.name}_func', '_${decl.name.pascalCase}', nativeTypedef, dartTypedef);
  }

  final String nativeName;
  final String dartName;
  final String native;
  final String dart;
}
