#include <stdio.h>
#include <stdlib.h>
#include <setjmp.h>
#include <string.h>
#include <stdbool.h>
#include <clang-c/Index.h>
#include <json-builder.h>
#include "helpers.h"

const char *clang_args[] = {};

jmp_buf error_thrown;

typedef enum WalkerStatus {
  WalkerStatus_OK = 0,
  WalkerStatus_UnparseableFile = 1,
  WalkerStatus_InvalidType = 2,
  WalkerStatus_UnhandledType = 3,
  WalkerStatus_UnhandledDeclaration = 4
} WalkerStatus;

void throw_error(WalkerStatus code) {
  longjmp(error_thrown, code);
}

typedef void (*WalkerErrorCallback)(char *);

typedef struct WalkerState {
  const char *message;
  json_value *json;
} WalkerState;

WalkerState *create_walker_state() {
  WalkerState *state = (WalkerState *)malloc(sizeof(WalkerState));
  state->json = json_array_new(0);
  return state;
}

typedef struct WalkerResult {
  WalkerStatus status;
  const char *data;
} WalkerResult;

json_value *new_declaration(CXCursor cursor, const char *type) {
  json_value *data = json_object_new(0);
  const char *name = unwrap_string(clang_getCursorSpelling(cursor));

  json_object_push(data, "type", json_string_new(type));
  json_object_push(data, "name", json_string_new(name));

  return data;
}

json_value *unwrap_type(CXType type, WalkerState *state) {
  if (type.kind == CXType_Invalid || type.kind == CXType_Unexposed) {
    state->message = "Encountered an invalid or unexposed type in an unexpected place";
    throw_error(WalkerStatus_InvalidType);
  }
  else if (type.kind < 100) {
    const char *name = unwrap_string(clang_getTypeKindSpelling(type.kind));
    return json_string_new(name);
  }
  else if (type.kind == CXType_Pointer) {
    json_value *pointer = json_object_new(0);
    json_object_push(pointer, "pointer", json_boolean_new(true));
    json_object_push(pointer, "value", unwrap_type(clang_getPointeeType(type), state));
    return pointer;
  }
  else if (type.kind == CXType_Record) {
    json_value *strct = json_object_new(0);
    const char *name = unwrap_string(clang_getTypeSpelling(type));
    json_object_push(strct, "kind", json_string_new("struct"));
    json_object_push(strct, "value", json_string_new(name));
    return strct;
  }
  else if (type.kind == CXType_Elaborated) {
    json_value *unwrapped = unwrap_type(clang_Type_getNamedType(type), state);
    json_value *result;
    if (unwrapped->type == json_object) {
      result = unwrapped;
    }
    else {
      result = json_object_new(0);
      json_object_push(result, "value", unwrapped);
    }
    json_object_push(result, "elaborated", json_boolean_new(true));
    return result;
  }

  state->message = concat_strings("Encountered a type that can't yet be handled: ", unwrap_string(clang_getTypeKindSpelling(type.kind)));
  throw_error(WalkerStatus_UnhandledType);
}

json_value *unwrap_function_args(CXCursor cursor, WalkerState *state) {
  json_value *args = json_array_new(0);
  int numArgs = clang_Cursor_getNumArguments(cursor);
  int i;

  for (i = 0; i < numArgs; ++i) {
    json_value *arg = json_object_new(0);
    CXCursor argCursor = clang_Cursor_getArgument(cursor, i);
    const char *argName = unwrap_string(clang_getCursorSpelling(argCursor));
    CXType argType = clang_getCursorType(argCursor);
    json_object_push(arg, "name", json_string_new(argName));
    json_object_push(arg, "type", unwrap_type(argType, state));
    json_array_push(args, arg);
  }

  return args;
}

json_value *visit_function(CXCursor cursor, WalkerState *state) {
  json_value *data = new_declaration(cursor, "function");
  CXType cxType = clang_getCursorType(cursor);
  CXType returnType = clang_getResultType(cxType);

  json_object_push(data, "returns", unwrap_type(returnType, state));
  json_object_push(data, "args", unwrap_function_args(cursor, state));
  json_object_push(data, "variadic", json_boolean_new(clang_isFunctionTypeVariadic(cxType)));

  return data;
}

enum CXVisitorResult struct_field_visitor(CXCursor cursor, CXClientData clientData) {
  WalkerState *state = *(WalkerState **)(clientData);
  json_value *field = json_object_new(0);

  const char *name = unwrap_string(clang_getCursorSpelling(cursor));
  CXType cxType = clang_getCursorType(cursor);
  json_object_push(field, "name", json_string_new(name));
  json_object_push(field, "type", unwrap_type(cxType, state));
  json_array_push(state->json, field);

  return CXVisit_Continue;
}

json_value *visit_struct(CXCursor cursor, WalkerState *state) {
  json_value *data = new_declaration(cursor, "struct");
  CXType cxType = clang_getCursorType(cursor);
  json_value *fields = json_array_new(0);
  json_value *mainState = state->json;
  state->json = fields;

  clang_Type_visitFields(cxType, struct_field_visitor, &state);

  json_object_push(data, "fields", fields);
  state->json = mainState;
  return data;
}

enum CXChildVisitResult visitor(CXCursor cursor, CXCursor parent, CXClientData clientData) {
  CXSourceLocation location = clang_getCursorLocation(cursor);
  if (!clang_Location_isFromMainFile(location)) return CXChildVisit_Continue;

  enum CXCursorKind cursorKind = clang_getCursorKind(cursor);
  WalkerState *state = *(WalkerState **)(clientData);

  switch (cursorKind) {
    case CXCursor_FunctionDecl:
      json_array_push(state->json, visit_function(cursor, state));
      break;
    case CXCursor_StructDecl:
      json_array_push(state->json, visit_struct(cursor, state));
      break;
    default: {
      const char *type = unwrap_string(clang_getCursorKindSpelling(cursorKind));
      state->message = concat_strings("Encountered a declaration that can't yet be handled: ", type);
      throw_error(WalkerStatus_UnhandledDeclaration);
    }
  }

  return CXChildVisit_Continue;
}

CXTranslationUnit parse_file(CXIndex *index, char *filename, WalkerState *state) {
  CXTranslationUnit tu = clang_createTranslationUnitFromSourceFile(
    *index,
    filename,
    0,
    clang_args,
    0,
    NULL
  );

  if (!tu) {
    state->message = "Unable to parse the provided header file";
    throw_error(WalkerStatus_UnparseableFile);
  }

  return tu;
}

WalkerResult *walk_clang_ast(char *header_filename) {
  WalkerState *state = create_walker_state();
  WalkerResult *result = (WalkerResult *)malloc(sizeof(WalkerResult));
  result->status = WalkerStatus_OK;

  CXIndex index = clang_createIndex(0, 1);
  CXTranslationUnit tu;

  int error_code = setjmp(error_thrown);
  if (error_code) {
    result->status = error_code;
    result->data = state->message;
  }
  else {
    tu = parse_file(&index, header_filename, state);
    CXCursor rootCursor = clang_getTranslationUnitCursor(tu);
    clang_visitChildren(rootCursor, visitor, &state);

    char *json_buf = malloc(json_measure(state->json));
    json_serialize(json_buf, state->json);
    result->data = json_buf;
  }

  if (tu) clang_disposeTranslationUnit(tu);
  clang_disposeIndex(index);
  json_builder_free(state->json);

  return result;
}
