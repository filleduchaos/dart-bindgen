import 'package:meta/meta.dart';
import 'package:bindgen/src/helpers.dart' show hashAll;

FfiType getTypeInformation(dynamic json) {
  if (json is String) {
    var builtin = _typeInfo[json];
    if (builtin == null) {
      throw ArgumentError('Unable to understand type $json');
    }

    return builtin;
  }

  var type = json as Map<String, dynamic>;
  var value = type['value'];

  if (type['pointer'] == true) {
    // Special case for strings
    if (value is String && _charTypes.contains(value)) {
      return const FfiType.string();
    }

    return FfiType.pointerFrom(getTypeInformation(value));
  }

  if (type['elaborated'] == true) {
    var kindStr = type['kind'] as String;
    if (kindStr == null) return getTypeInformation(value);

    var kind = _kindFromString(kindStr);
    value = (value as String).replaceFirst('$kindStr ', '');
    return FfiType(native: value, dart: value, kind: kind);
  }

  throw ArgumentError('Unable to understand type $json');
}

const _typeInfo = {
  // Not yet sure how to handle booleans? Contribute that to SDK?
  // 'Bool': _Info()
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
  // 'ULongLong': _Info(),
  'Float': FfiType.double('ffi.Float'),
  'Double': FfiType.double('ffi.Double'),
};

const _charTypes = ['Char_U', 'Char_S', 'UChar', 'SChar'];

enum FfiTypeKind {
  primitive,
  string,
  struct,
  enumerated,
}

FfiTypeKind _kindFromString(String str) {
  switch (str) {
    case 'primitive': return FfiTypeKind.primitive;
    case 'string': return FfiTypeKind.string;
    case 'struct': return FfiTypeKind.struct;
    case 'enumerated': return FfiTypeKind.enumerated;
    default: throw ArgumentError('Invalid ffi type kind: $str');
  }
}

class FfiType {
  const FfiType({
    @required this.native,
    @required this.dart,
    @required this.kind,
    this.pointerDepth = 0,
  });

  const FfiType.primitive({ @required this.native, @required this.dart })
    : kind = FfiTypeKind.primitive, pointerDepth = 0;

  const FfiType.int(String native) : this.primitive(dart: 'int', native: native);

  const FfiType.double(String native) : this.primitive(dart: 'double', native: native);

  FfiType.pointerFrom(FfiType pointee)
    : native = 'ffi.Pointer<${pointee.native}>',
      dart = 'ffi.Pointer<${pointee.dart}>',
      kind = pointee.kind,
      pointerDepth = pointee.pointerDepth + 1;

  const FfiType._utf({ int size })
    : native = 'ffi.Pointer<ffi.Utf$size>',
      dart = 'ffi.Pointer<ffi.Utf$size>',
      kind = FfiTypeKind.string,
      pointerDepth = 0;

  const FfiType.string() : this._utf(size: 8);
  const FfiType.string16() : this._utf(size: 16);

  final String native;
  final String dart;
  final FfiTypeKind kind;
  final int pointerDepth;

  bool get isPointer => pointerDepth > 0;
  bool get isPrimitive => kind == FfiTypeKind.primitive && dart != 'void';

  operator ==(other) {
    return other is FfiType &&
      other.dart == dart &&
      other.native == native &&
      other.kind == kind;
  }

  @override
  int get hashCode => hashAll([native, dart, kind, pointerDepth]);
}
