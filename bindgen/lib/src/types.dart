import 'package:meta/meta.dart';
import 'package:bindgen/src/helpers.dart' show hashAll;

FfiType getTypeInformation(dynamic json) {
  if (json is String) return _getBuiltin(json);

  var type = json as Map<String, dynamic>;

  if (type['pointer'] == true) {
    var value = type['value'];
    // Special case for strings
    if (value is String && _charTypes.contains(value)) {
      return const FfiType.string();
    }

    return FfiType.pointerFrom(getTypeInformation(value));
  }

  if (type['elaborated'] == true) {
    return _getElaboratedType(type);
  }

  throw ArgumentError('Unable to understand type $type');
}


FfiType _getBuiltin(String type) {
  var builtin = _typeInfo[type];
  if (builtin == null) {
    throw ArgumentError('Unable to understand type $type');
  }

  return builtin;
}

FfiType _getElaboratedType(Map<String, dynamic> type) {
  var value = type['value'];

  var kindStr = type['kind'] as String;

  if (kindStr == null) return getTypeInformation(value);

  var kind = _kindFromString(kindStr);
  value = (value as String).replaceFirst('$kindStr ', '');

  if (type['type'] == null) return FfiType(native: value, dart: value, kind: kind);

  var underlying = getTypeInformation(type['type']);
  return FfiType(
    native: underlying.native,
    dart: underlying.dart,
    alias: value,
    kind: kind,
    pointerDepth: underlying.pointerDepth,
  );
}

const _typeInfo = {
  // Should probably still contribute it to the SDK but this works for now?
  // also this is VERY LIKELY not necessarily cross-platform compatible 😬
  'Bool': FfiType(native: 'ffi.Uint8', dart: 'int', alias: 'bool', kind: FfiTypeKind.boolean),
  'Void': FfiType.primitive(native: 'ffi.Void', dart: 'void'),
  'Char_U': FfiType.int('ffi.Uint8'),
  'Char_S': FfiType.int('ffi.Uint8'),
  'UChar': FfiType.int('ffi.Uint8'),
  'SChar': FfiType.int('ffi.Int8'),
  'UShort': FfiType.int('ffi.Uint16'),
  'Short': FfiType.int('ffi.Int16'),
  'UInt': FfiType.int('ffi.Uint32'),
  'Int': FfiType.int('ffi.Int32'),
  'ULong': FfiType.int('ffi.Uint64'),
  'Long': FfiType.int('ffi.Int64'),
  // Not yet sure how to handle long longs?
  // 'ULongLong': FfiType(),
  'Float': FfiType.double('ffi.Float'),
  'Double': FfiType.double('ffi.Double'),
};

const _charTypes = ['Char_U', 'Char_S', 'UChar', 'SChar'];

enum FfiTypeKind {
  primitive,
  string,
  struct,
  enumerated,
  boolean,
}

FfiTypeKind _kindFromString(String str) {
  switch (str) {
    case 'primitive': return FfiTypeKind.primitive;
    case 'string': return FfiTypeKind.string;
    case 'struct': return FfiTypeKind.struct;
    case 'enum': return FfiTypeKind.enumerated;
    default: throw ArgumentError('Invalid ffi type kind: $str');
  }
}

@sealed
class FfiType {
  static const _aliasedTypes = { FfiTypeKind.enumerated, FfiTypeKind.boolean, FfiTypeKind.string };

  const FfiType({
    @required this.native,
    @required this.dart,
    this.alias,
    @required this.kind,
    this.pointerDepth = 0,
  });

  const FfiType.primitive({ @required this.native, @required this.dart })
    : kind = FfiTypeKind.primitive, pointerDepth = 0, alias = null;

  const FfiType.int(String native) : this.primitive(dart: 'int', native: native);

  const FfiType.double(String native) : this.primitive(dart: 'double', native: native);

  FfiType.pointerFrom(FfiType pointee)
    : native = 'ffi.Pointer<${pointee.native}>',
      dart = 'ffi.Pointer<${pointee._pointeeDartType}>',
      alias = null,
      kind = pointee.kind,
      pointerDepth = pointee.pointerDepth + 1;

  const FfiType._utf({ int size })
    : native = 'ffi.Pointer<ffi.Utf$size>',
      dart = 'ffi.Pointer<ffi.Utf$size>',
      alias = 'String',
      kind = FfiTypeKind.string,
      pointerDepth = 0;

  const FfiType.string() : this._utf(size: 8);
  const FfiType.string16() : this._utf(size: 16);

  final String native;
  final String dart;
  final String alias;
  final FfiTypeKind kind;
  final int pointerDepth;

  bool get isPointer => pointerDepth > 0;
  bool get isPrimitive => kind == FfiTypeKind.primitive && dart != 'void';
  bool get isEnum => kind == FfiTypeKind.enumerated;
  bool get isAliased => _aliasedTypes.contains(kind);

  String get _pointeeDartType => isPrimitive ? native : dart;

  String get dartRepresentation => isAliased ? alias : dart;

  @override
  operator ==(other) {
    return other is FfiType &&
      other.dart == dart &&
      other.native == native &&
      other.alias == alias &&
      other.kind == kind &&
      other.pointerDepth == pointerDepth;
  }

  @override
  int get hashCode => hashAll([native, dart, alias, kind, pointerDepth]);
}
