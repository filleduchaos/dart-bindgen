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

static json_value *unwrap_record(CXType type) {
  json_value *strct = json_object_new(0);
  const char *name = unwrap_string(clang_getTypeSpelling(type));
  json_object_push(strct, "kind", json_string_new("struct"));
  json_object_push(strct, "value", json_string_new(name));
  return strct;
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
    return unwrap_pointer(type);
  else if (type.kind == CXType_Elaborated)
    return unwrap_elaborated(type);
  else
    throw(&UnhandledTypeException, unwrap_string(clang_getTypeKindSpelling(type.kind)));
}
