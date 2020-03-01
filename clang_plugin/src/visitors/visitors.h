#include <stdbool.h>
#include "../helpers.h"
#include <json-builder.h>

void traverse_root(CXCursor cursor, CursorDeque *deque);

json_value *visit_cursor(CXCursor cursor, CursorDeque *deque);

json_value *new_declaration(CXCursor cursor, const char *type);

json_value *unwrap_type(CXType type, CursorDeque *deque);

json_value *visit_function(CXCursor cursor, CursorDeque *deque);

json_value *visit_struct(CXCursor cursor, CursorDeque *deque);

json_value *visit_enum(CXCursor cursor, CursorDeque *deque);
