#include "visitors.h"
#include "../helpers.h"
#include "../exceptions.h"

static enum CXVisitorResult struct_field_visitor(CXCursor cursor, CXClientData clientData) {
  json_value *struct_fields = *(json_value **)(clientData);
  json_value *field = json_object_new(0);

  const char *name = unwrap_string(clang_getCursorSpelling(cursor));
  CXType cxType = clang_getCursorType(cursor);
  json_object_push(field, "name", json_string_new(name));
  json_object_push(field, "type", unwrap_type(cxType));
  json_array_push(struct_fields, field);

  return CXVisit_Continue;
}

json_value *visit_struct(CXCursor cursor) {
  json_value *data = new_declaration(cursor, "struct");
  CXType cxType = clang_getCursorType(cursor);
  json_value *fields = json_array_new(0);

  clang_Type_visitFields(cxType, struct_field_visitor, &fields);

  json_object_push(data, "fields", fields);
  return data;
}
