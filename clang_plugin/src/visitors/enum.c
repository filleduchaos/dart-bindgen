#include "visitors.h"
#include "../exceptions.h"
#include "../helpers.h"

static enum CXChildVisitResult visitor(CXCursor cursor, CXCursor parent, CXClientData clientData) {
  enum CXCursorKind cursorKind = clang_getCursorKind(cursor);

  if (clang_getCursorKind(cursor) != CXCursor_EnumConstantDecl) {
    const char *type = unwrap_string(clang_getCursorKindSpelling(cursorKind));
    throw(&UnhandledDeclarationException, type);
  }

  const char *name = unwrap_string(clang_getCursorSpelling(cursor));
  long long value = clang_getEnumConstantDeclValue(cursor);
  json_object_push((json_value *)(clientData), name, json_integer_new(value));

  return CXChildVisit_Continue;
}

json_value *visit_enum(CXCursor cursor) {
  json_value *data = new_declaration(cursor, "enum");
  CXType underlyingType = clang_getEnumDeclIntegerType(cursor);
  json_value *constants = json_object_new(0);

  clang_visitChildren(cursor, visitor, constants);
  
  json_object_push(data, "underlying", unwrap_type(underlyingType));
  json_object_push(data, "constants", constants);
  return data;
}
