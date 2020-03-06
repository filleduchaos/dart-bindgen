#include "visitors.h"
#include "../exceptions.h"

static void push_if_external_declaration(CXType type, CursorDeque *deque) {
  CXCursor cursor = clang_getTypeDeclaration(type);
  CXSourceLocation location = clang_getCursorLocation(cursor);
  if (clang_Location_isFromMainFile(location)) return;

  push_cursor(deque, cursor);
}

static json_value *unwrap_primitive(CXType type) {
  const char *name = unwrap_string(clang_getTypeKindSpelling(type.kind));
  return json_string_new(name);
}

static json_value *unwrap_pointer(CXType type, CursorDeque *deque) {
  json_value *pointer = json_object_new(0);
  json_value *unwrapped = unwrap_type(clang_getPointeeType(type), deque);
  json_object_push(pointer, "pointer", json_boolean_new(true));
  json_object_push(pointer, "value", unwrapped);
  return pointer;
}

static json_value *unwrap_user_defined(CXType type, const char *kind, CursorDeque *deque) {
  json_value *userdef = json_object_new(0);
  const char *name = unwrap_string(clang_getTypeSpelling(type));
  json_object_push(userdef, "kind", json_string_new(kind));
  json_object_push(userdef, "value", json_string_new(name));

  // Queue up exposed types defined in other files
  push_if_external_declaration(type, deque);
  return userdef;
}

static json_value *unwrap_struct(CXType type, CursorDeque *deque) {
  return unwrap_user_defined(type, "struct", deque);
}

static json_value *unwrap_enum(CXType type, CursorDeque *deque) {
  json_value *enumm = unwrap_user_defined(type, "enum", deque);
  CXCursor cursor = clang_getTypeDeclaration(type);
  CXType underlyingType = clang_getEnumDeclIntegerType(cursor);
  json_object_push(enumm, "type", unwrap_type(underlyingType, deque));
  return enumm;
}

static json_value *unwrap_elaborated(CXType type, CursorDeque *deque) {
  json_value *unwrapped = unwrap_type(clang_Type_getNamedType(type), deque);
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

static json_value *unwrap_typedef(CXType type, CursorDeque *deque) {
  CXType canonicalType = clang_getCanonicalType(type);
  return unwrap_type(canonicalType, deque);
}

json_value *unwrap_type(CXType type, CursorDeque *deque) {
  if (type.kind == CXType_Invalid || type.kind == CXType_Unexposed)
    throw(&InvalidTypeException, NULL);
  else if (type.kind < 100)
    return unwrap_primitive(type);
  else if (type.kind == CXType_Pointer)
    return unwrap_pointer(type, deque);
  else if (type.kind == CXType_Record)
    return unwrap_struct(type, deque);
  else if (type.kind == CXType_Enum)
    return unwrap_enum(type, deque);
  else if (type.kind == CXType_Typedef)
    return unwrap_typedef(type, deque);
  else if (type.kind == CXType_Elaborated)
    return unwrap_elaborated(type, deque);
  else
    throw(&UnhandledTypeException, unwrap_string(clang_getTypeKindSpelling(type.kind)));
}
