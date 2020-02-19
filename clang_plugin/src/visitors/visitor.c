#include "visitors.h"
#include "../helpers.h"
#include "../exceptions.h"

static DeclarationVisitor visitor_for(CXCursor cursor) {
  enum CXCursorKind cursorKind = clang_getCursorKind(cursor);

  switch (cursorKind) {
    case CXCursor_FunctionDecl:
      return visit_function;
    case CXCursor_StructDecl:
      return visit_struct;
    case CXCursor_EnumDecl:
      return visit_enum;
    default: {
      const char *type = unwrap_string(clang_getCursorKindSpelling(cursorKind));
      throw(&UnhandledDeclarationException, type);
    }
  }
}

static enum CXChildVisitResult visitor(CXCursor cursor, CXCursor parent, CXClientData clientData) {
  CXSourceLocation location = clang_getCursorLocation(cursor);
  if (!clang_Location_isFromMainFile(location)) return CXChildVisit_Continue;

  json_value *state = (json_value *)(clientData);
  DeclarationVisitor visit_decl = visitor_for(cursor);
  json_array_push(state, (*visit_decl)(cursor));

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
