import 'package:recase/recase.dart';
import 'package:bindgen/src/code_buffer.dart';
import 'package:bindgen/src/declaration.dart';
import 'package:bindgen/src/types.dart';

void definition<T extends Declaration>(CodeBuffer buf, Iterable<T> declarations) {
  void Function(CodeBuffer, T) definer = (() {
    switch (T) {
      case EnumDeclaration: return _defineEnum;
      case StructDeclaration: return _defineStruct;
      case FunctionDeclaration: return _defineFunction;
      default: throw ArgumentError('$T should be a top-level declaration type');
    }
  })();

  for (var decl in declarations) {
    definer(buf, decl);
  }
  buf.addLine();
}

void _defineEnum(CodeBuffer buf, EnumDeclaration decl) {
  if (decl.isSimple) {
    buf.addEnum(decl.name, constants: decl.constants.keys);
  }
  else {
    buf.addClass(decl.name, builder: (classBuf) {
      classBuf.addSpacedLine('const ${decl.name}._(this.index, this.name);');
      classBuf.addLine('final int index;');
      classBuf.addSpacedLine('final String name;');

      classBuf.addFunction('toString', returns: 'String', override: true, expression: "'${decl.name}.\${name}'");
      classBuf.addLine();
      
      decl.constants.forEach((constant, value) {
        // Hack to get around `values` being a "reserved" field
        var name = constant == 'values' ? '\$values' : constant;
        classBuf.addLine("static const $name = ${decl.name}._($value, '$constant');");
      });

      classBuf.addLine();
      classBuf.addArray('static const values', decl.constants.keys.toList());
    });
  }

  buf.addLine();
}

void _defineStruct(CodeBuffer buf, StructDeclaration decl) {
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

void _defineFunction(CodeBuffer buf, FunctionDeclaration decl) {
  var def = decl.typedef;

  buf.assertTopLevel();
  buf.addLine('typedef ${def.nativeName} = ${def.native};');
  if (def.dart != def.native) {
    buf.addLine('typedef ${def.dartName} = ${def.dart};');
  }
  buf.addLine();
}

void symbolLookup(CodeBuffer buf, String name) {
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
      funcBuf.closeBlock(addLine: true);
      funcBuf.addLine('return func as T;');
    }
  );
}

void functions(CodeBuffer buf, Iterable<FunctionDeclaration> funcs) {
  for (var func in funcs) {
    buf.addLine();
    buf.addFunction(
      func.name.camelCase,
      returns: func.returnType.dartRepresentation,
      args: func.arguments.map((arg) => arg.dartRepresentation),
      builder: (funcBuf) => _writeFunctionStub(funcBuf, func),
    );
  }
}

void _writeFunctionStub(CodeBuffer buf, FunctionDeclaration func) {
  final def = func.typedef;
  var dartType = def.dart == def.native ? def.nativeName : def.dartName;
  final args = func.arguments.map((arg) => arg.type.cValueOf(arg.name)).join(', ');
  var name = "'${func.name}'";

  buf.addLine('${func.returnType.dart} result;');
  buf.addLine('var cachedFunc = _\$getDartFunctionFromCache<$dartType>($name);');
  buf.openBlock('if (cachedFunc != null)');
  buf.addLine('result = cachedFunc($args);');
  buf.closeBlock();
  buf.openBlock('else');
  buf.addLine('_symbolCache[$name] = _lib.lookupFunction<${def.nativeName}, ${dartType}>($name);');
  buf.addLine('result = _symbolCache[$name]($args);');
  buf.closeBlock();
  buf.addLine('return ${func.returnType.dartValueOf('result')};');
}

extension on FfiType {
  String cValueOf(String expression) {
    if (pointerDepth != 0) return expression;

    switch (kind) {
      case FfiTypeKind.enumerated:
        return '($expression).index';
      case FfiTypeKind.boolean:
        return '($expression ? 1 : 0)';
      case FfiTypeKind.string:
        return 'ffi.Utf8.toUtf8($expression)';
      default:
        return expression;
    }
  }

  String dartValueOf(String expression) {
    if (pointerDepth != 0) return expression;

    switch (kind) {
      case FfiTypeKind.enumerated:
        return '$alias.values.firstWhere((v) => v.index == $expression)';
      case FfiTypeKind.boolean:
        return '!($expression == 0)';
      case FfiTypeKind.string:
        return 'ffi.Utf8.fromUtf8($expression)';
      default:
        return expression;
    }
  }
}
