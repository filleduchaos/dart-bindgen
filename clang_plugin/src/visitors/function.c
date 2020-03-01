#include "visitors.h"
#include "../exceptions.h"

static json_value *unwrap_function_args(CXCursor cursor, CursorDeque *deque) {
  json_value *args = json_array_new(0);
  int numArgs = clang_Cursor_getNumArguments(cursor);
  int i;

  for (i = 0; i < numArgs; ++i) {
    json_value *arg = json_object_new(0);
    CXCursor argCursor = clang_Cursor_getArgument(cursor, i);
    const char *argName = unwrap_string(clang_getCursorSpelling(argCursor));
    CXType argType = clang_getCursorType(argCursor);
    json_object_push(arg, "name", json_string_new(argName));
    json_object_push(arg, "type", unwrap_type(argType, deque));
    json_array_push(args, arg);
  }

  return args;
}

json_value *visit_function(CXCursor cursor, CursorDeque *deque) {
  json_value *data = new_declaration(cursor, "function");
  CXType cxType = clang_getCursorType(cursor);
  CXType returnType = clang_getResultType(cxType);

  json_object_push(data, "returns", unwrap_type(returnType, deque));
  json_object_push(data, "args", unwrap_function_args(cursor, deque));
  json_object_push(data, "variadic", json_boolean_new(clang_isFunctionTypeVariadic(cxType)));

  return data;
}
