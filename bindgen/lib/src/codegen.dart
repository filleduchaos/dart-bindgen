import 'package:recase/recase.dart';
import 'package:bindgen/src/code_buffer.dart';
import 'package:bindgen/src/declaration.dart';
import 'package:bindgen/src/types.dart';

const idiomaticConverterClass = '''
abstract class _\$ {
  static T enumFromC<T>(List<T> values, int index) =>
    nullOr(index, (i) => values.firstWhere((dynamic v) => v.index == i));

  static int boolToC(bool value) => nullOr(value, (v) => v ? 1 : 0);

  static bool boolFromC(int value) => nullOr(value, (v) => !(v == 0));

  static ffi.Pointer<ffi.Utf8> stringToC(String value) => nullOr(value, ffi.Utf8.toUtf8);

  static String stringFromC(ffi.Pointer<ffi.Utf8> value) => nullOr(value, ffi.Utf8.fromUtf8);

  static O nullOr<I, O>(I foo, O Function(I) transform) =>
    foo == null ? null : transform(foo);
}''';

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

      if (field.type.isAliased) {
        var name = '\$${field.name}';
        classBuf.addLine('${field.type.dart} $name;');
        classBuf.addGetter(
          field.name,
          type: field.type.alias,
          expression: '${field.type.dartValueOf(name)}',
        );
        classBuf.addSetter(
          field.name,
          type: field.type.alias,
          expression: "$name = ${field.type.cValueOf('value')}",
        );
      }
      else {
        classBuf.addLine('${field.type.dart} ${field.name};');
      }
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
    '_\$functionFromCache',
    typeParams: ['T extends Function', 'F extends Function'],
    returns: 'F',
    args: ['String name', 'F Function(ffi.Pointer<ffi.NativeFunction<T>> funcPtr) toFunc'],
    builder: (CodeBuffer funcBuf) {
      funcBuf.openBlock('if (_symbolCache[name] == null)');
      funcBuf.addLine("_lib ??= \$open('$name');");
      funcBuf.addLine('var funcPtr = _lib.lookup<ffi.NativeFunction<T>>(name);');
      funcBuf.addLine('_symbolCache[name] = toFunc(funcPtr);');
      funcBuf.closeBlock(addLine: true);
      funcBuf.addLine('return _symbolCache[name] as F;');
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
  var toFunc = '(p) => p.asFunction<$dartType>()';

  buf.addLine('var _func = _\$functionFromCache<${def.nativeName}, ${dartType}>($name, $toFunc);');
  buf.addLine('var _result = _func($args);');
  buf.addLine('return ${func.returnType.dartValueOf('_result')};');
}

extension on FfiType {
  String cValueOf(String expression) {
    if (pointerDepth != 0) return expression;

    switch (kind) {
      case FfiTypeKind.enumerated:
        return '$expression?.index';
      case FfiTypeKind.boolean:
        return '_\$.boolToC($expression)';
      case FfiTypeKind.string:
        return '_\$.stringToC($expression)';
      default:
        return expression;
    }
  }

  String dartValueOf(String expression) {
    if (pointerDepth != 0) return expression;

    switch (kind) {
      case FfiTypeKind.enumerated:
        return '_\$.enumFromC($alias.values, $expression)';
      case FfiTypeKind.boolean:
        return '_\$.boolFromC($expression)';
      case FfiTypeKind.string:
        return '_\$.stringFromC($expression)';
      default:
        return expression;
    }
  }
}
