#include "visitors.h"
#include "../helpers.h"
#include "../exceptions.h"

static enum CXChildVisitResult visitor(CXCursor cursor, CXCursor parent, CXClientData clientData) {
  CXSourceLocation location = clang_getCursorLocation(cursor);
  if (!clang_Location_isFromMainFile(location)) return CXChildVisit_Continue;

  enum CXCursorKind cursorKind = clang_getCursorKind(cursor);
  json_value *state = (json_value *)(clientData);

  switch (cursorKind) {
    case CXCursor_FunctionDecl:
      json_array_push(state, visit_function(cursor));
      break;
    case CXCursor_StructDecl:
      json_array_push(state, visit_struct(cursor));
      break;
    default: {
      const char *type = unwrap_string(clang_getCursorKindSpelling(cursorKind));
      throw(&UnhandledDeclarationException, type);
    }
  }

  return CXChildVisit_Continue;
}

void traverse_root(CXCursor cursor, json_value *state) {
  clang_visitChildren(cursor, visitor, state);
}

json_value *new_declaration(CXCursor cursor, const char *type) {
  json_value *data = json_object_new(0);
  const char *name = unwrap_string(clang_getCursorSpelling(cursor));

  json_object_push(data, "name", json_string_new(name));
  json_object_push(data, "type", json_string_new(type));

  return data;
}
