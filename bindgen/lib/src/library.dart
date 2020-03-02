import 'package:meta/meta.dart';
import 'package:recase/recase.dart';
import 'package:bindgen/src/code_buffer.dart';
import 'package:bindgen/src/declaration.dart';
import 'package:bindgen/src/codegen.dart' as generate;

extension<E> on Iterable<E> {
  bool anyType<T extends E>() {
    for (var element in this) {
      if (element is T) return true;
    }
    return false;
  }
}

class Library {
  const Library({
    @required this.name,
    @required this.members,
  });

  final String name;
  final List<Declaration> members;

  bool get hasFunctionDeclarations => members.anyType<FunctionDeclaration>();

  String toDart() {
    final buf = CodeBuffer();

    buf.addLine('/// Auto-generated file: Do not edit unless you know what you are doing');
    buf.addLine('/// Dart bindings for $name, generated by bindgen');
    buf.addImport('dart:ffi', as: 'ffi');
    buf.addImport('package:ffi/ffi.dart', as: 'ffi');
    buf.addImport('package:dlopen/dlopen.dart', show: 'DlOpen');
    buf.addLine();

    generate.definition(buf, members.whereType<EnumDeclaration>());
    generate.definition(buf, members.whereType<StructDeclaration>());

    if (hasFunctionDeclarations) {
      generate.definition(buf, members.whereType<FunctionDeclaration>());

      buf.addClass('Lib${name.pascalCase}', builder: (classBuf) {
        generate.symbolLookup(classBuf, name);
        generate.functions(classBuf, members.whereType<FunctionDeclaration>());
      });
      buf.addLine();
    }

    buf.addLine(generate.idiomaticConverterClass);

    return buf.toString();
  }
}
