import 'package:meta/meta.dart';
import 'package:recase/recase.dart';
import 'package:bindgen/src/code_buffer.dart';
import 'package:bindgen/src/declaration.dart';

class Library {
  const Library({
    @required this.name,
    @required this.members,
  });

  final String name;
  final List<Declaration> members;

  String toDart() {
    final buf = CodeBuffer();

    buf.addLine('/// Auto-generated file: Do not edit unless you know what you are doing');
    buf.addLine('/// Dart bindings for $name, generated by bindgen');
    buf.addImport('dart:ffi', as: 'ffi');
    buf.addImport('package:ffi/ffi.dart', as: 'ffi');
    buf.addImport('package:dlopen/dlopen.dart', show: 'DlOpen');
    buf.addLine();

    for (var struct in members.whereType<StructDeclaration>()) {
      _writeStruct(buf, struct);
    }
    buf.addLine();

    for (var func in members.whereType<FunctionDeclaration>()) {
      _writeFunctionDef(buf, func);
    }
    buf.addLine();

    buf.addClass('Lib${name.pascalCase}', builder: (classBuf) {
      _writeSymbolLookup(classBuf, name);
      _writeFunctions(classBuf, members.whereType<FunctionDeclaration>());
    });

    return buf.toString();
  }
}

void _writeStruct(CodeBuffer buf, StructDeclaration decl) {
  buf.addClass(decl.name, parent: 'ffi.Struct', builder: (classBuf) {
    var lastField = decl.fields.last;
    for (var field in decl.fields) {
      if (field.type.isPrimitive) classBuf.addLine('@${field.type.native}()');
      classBuf.addLine('${field.type.dart} ${field.name};');
      if (field != lastField) classBuf.addLine();
    }
  });
  buf.addLine();
}

void _writeFunctionDef(CodeBuffer buf, FunctionDeclaration decl) {
  var def = decl.typedef;

  buf.assertTopLevel();
  buf.addLine('typedef ${def.nativeName} = ${def.native};');
  if (def.dart != def.native) {
    buf.addLine('typedef ${def.dartName} = ${def.dart};');
  }
  buf.addLine();
}

void _writeSymbolLookup(CodeBuffer buf, String name) {
  buf.addLine('static ffi.DynamicLibrary _lib;');
  buf.addLine('static final _symbolCache = <String, Function>{};');
  buf.addLine('static final \$open = DlOpen();');
  buf.addLine();
  buf.addFunction(
    '_\$getDartFunctionFromCache',
    typeParams: ['T'],
    returns: 'T',
    args: ['String name'],
    builder: (CodeBuffer funcBuf) {
      funcBuf.addLine('final func = _symbolCache[name];');
      funcBuf.openBlock('if (func == null)');
      funcBuf.addLine("_lib ??= \$open('$name');");
      funcBuf.closeBlock();
      funcBuf.addLine();
      funcBuf.addLine('return func as T;');
    }
  );
}

void _writeFunctions(CodeBuffer buf, Iterable<FunctionDeclaration> funcs) {
  for (var func in funcs) {
    final def = func.typedef;
    var dartType = def.dart == def.native ? def.nativeName : def.dartName;
    final args = func.arguments.map((arg) => arg.name).join(', ');
    var name = "'${func.name}'";

    buf.addLine();
    buf.addFunction(
      func.name.camelCase,
      returns: func.returnType.dart,
      args: func.arguments.map((arg) => arg.inDart),
      builder: (funcBuf) {
        
        funcBuf.addLine('var cachedFunc = _\$getDartFunctionFromCache<$dartType>($name);');
        funcBuf.addLine('if (cachedFunc != null) return cachedFunc($args);');
        funcBuf.addLine();
        funcBuf.addLine('_symbolCache[$name] = _lib.lookupFunction<${def.nativeName}, ${dartType}>($name);');
        funcBuf.addLine('return _symbolCache[$name]($args);');
      },
    );
  }
}
