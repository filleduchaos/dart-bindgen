#include "visitors.h"
#include "../exceptions.h"

typedef struct {
  json_value *fields;
  CursorDeque *deque;
} StructChildren;

static enum CXVisitorResult struct_field_visitor(CXCursor cursor, CXClientData clientData) {
  StructChildren *children = clientData;
  json_value *field = json_object_new(0);

  const char *name = unwrap_string(clang_getCursorSpelling(cursor));
  CXType cxType = clang_getCursorType(cursor);
  json_object_push(field, "name", json_string_new(name));
  json_object_push(field, "type", unwrap_type(cxType, children->deque));
  json_array_push(children->fields, field);

  return CXVisit_Continue;
}

json_value *visit_struct(CXCursor cursor, CursorDeque *deque) {
  json_value *data = new_declaration(cursor, "struct");
  CXType cxType = clang_getCursorType(cursor);
  json_value *fields = json_array_new(0);

  StructChildren children = { fields, deque };

  clang_Type_visitFields(cxType, struct_field_visitor, &children);

  json_object_push(data, "fields", fields);
  return data;
}
