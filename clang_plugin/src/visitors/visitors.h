#include <clang-c/Index.h>
#include <json-builder.h>

void traverse_root(CXCursor cursor, json_value *state);

json_value *new_declaration(CXCursor cursor, const char *type);

json_value *unwrap_type(CXType type);


typedef json_value *(*DeclarationVisitor)(CXCursor cursor);

json_value *visit_function(CXCursor cursor);

json_value *visit_struct(CXCursor cursor);

json_value *visit_enum(CXCursor cursor);
