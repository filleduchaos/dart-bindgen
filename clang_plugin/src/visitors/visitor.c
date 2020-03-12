#include "visitors.h"
#include "../exceptions.h"

static json_value *visit_typedef(CXCursor cursor, CursorDeque *deque) {
  CXType canonicalType = clang_getTypedefDeclUnderlyingType(cursor);
  push_cursor(deque, clang_getTypeDeclaration(canonicalType));
  return NULL;
}

json_value *visit_cursor(CXCursor cursor, CursorDeque *deque) {
  enum CXCursorKind cursorKind = clang_getCursorKind(cursor);

  switch (cursorKind) {
    case CXCursor_FunctionDecl:
      return visit_function(cursor, deque);
    case CXCursor_StructDecl:
      return visit_struct(cursor, deque);
    case CXCursor_EnumDecl:
      return visit_enum(cursor, deque);
    case CXCursor_TypedefDecl:
      return visit_typedef(cursor, deque);
    case CXCursor_InclusionDirective:
    case CXCursor_MacroExpansion:
      // A very weird hack but bear with it
      return NULL;
    default: {
      const char *type = unwrap_string(clang_getCursorKindSpelling(cursorKind));
      throw(&UnhandledDeclarationException, type);
    }
  }
}

static enum CXChildVisitResult queue_declarations(CXCursor cursor, CXCursor parent, CXClientData clientData) {
  CXSourceLocation location = clang_getCursorLocation(cursor);

  if (!clang_Location_isInSystemHeader(location)) {
    queue_cursor(clientData, cursor);
  }

  return CXChildVisit_Continue;
}

void traverse_root(CXCursor rootCursor, CursorDeque *deque) {
  clang_visitChildren(rootCursor, queue_declarations, deque);
}

json_value *new_declaration(CXCursor cursor, const char *type) {
  json_value *data = json_object_new(0);
  const char *name = unwrap_string(clang_getCursorSpelling(cursor));

  json_object_push(data, "name", json_string_new(name));
  json_object_push(data, "type", json_string_new(type));

  return data;
}
