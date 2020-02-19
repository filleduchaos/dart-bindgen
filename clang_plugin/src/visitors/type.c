#include "visitors.h"
#include "../exceptions.h"
#include "../helpers.h"

static json_value *unwrap_primitive(CXType type) {
  const char *name = unwrap_string(clang_getTypeKindSpelling(type.kind));
  return json_string_new(name);
}

static json_value *unwrap_pointer(CXType type) {
  json_value *pointer = json_object_new(0);
  json_object_push(pointer, "pointer", json_boolean_new(true));
  json_object_push(pointer, "value", unwrap_type(clang_getPointeeType(type)));
  return pointer;
}

static json_value *unwrap_user_defined(CXType type, const char *kind) {
  json_value *userdef = json_object_new(0);
  const char *name = unwrap_string(clang_getTypeSpelling(type));
  json_object_push(userdef, "kind", json_string_new(kind));
  json_object_push(userdef, "value", json_string_new(name));
  return userdef;
}

static json_value *unwrap_struct(CXType type) {
  return unwrap_user_defined(type, "struct");
}

static json_value *unwrap_enum(CXType type) {
  json_value *enumm = unwrap_user_defined(type, "enum");
  CXCursor cursor = clang_getTypeDeclaration(type);
  CXType underlyingType = clang_getEnumDeclIntegerType(cursor);
  json_object_push(enumm, "type", unwrap_type(underlyingType));
  return enumm;
}

static json_value *unwrap_elaborated(CXType type) {
  json_value *unwrapped = unwrap_type(clang_Type_getNamedType(type));
  json_value *result;
  if (unwrapped->type == json_object)
    result = unwrapped;
  else {
    result = json_object_new(0);
    json_object_push(result, "value", unwrapped);
  }
  json_object_push(result, "elaborated", json_boolean_new(true));
  return result;
}

json_value *unwrap_type(CXType type) {
  if (type.kind == CXType_Invalid || type.kind == CXType_Unexposed)
    throw(&InvalidTypeException, NULL);
  else if (type.kind < 100)
    return unwrap_primitive(type);
  else if (type.kind == CXType_Pointer)
    return unwrap_pointer(type);
  else if (type.kind == CXType_Record)
    return unwrap_struct(type);
  else if (type.kind == CXType_Enum)
    return unwrap_enum(type);
  else if (type.kind == CXType_Elaborated)
    return unwrap_elaborated(type);
  else
    throw(&UnhandledTypeException, unwrap_string(clang_getTypeKindSpelling(type.kind)));
}
