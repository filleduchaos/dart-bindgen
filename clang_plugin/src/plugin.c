#include <clang-c/Index.h>
#include <json-builder.h>
#include "helpers.h"
#include "exceptions.h"

const char *clang_args[] = {};

typedef enum WalkerStatus {
  WalkerStatus_OK = 0,
  WalkerStatus_Error = 1,
} WalkerStatus;

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

json_value *unwrap_type(CXType type) {
  if (type.kind == CXType_Invalid || type.kind == CXType_Unexposed) {
    throw(&InvalidTypeException, NULL);
  }
  else if (type.kind < 100) {
    const char *name = unwrap_string(clang_getTypeKindSpelling(type.kind));
    return json_string_new(name);
  }
  else if (type.kind == CXType_Pointer) {
    json_value *pointer = json_object_new(0);
    json_object_push(pointer, "pointer", json_boolean_new(true));
    json_object_push(pointer, "value", unwrap_type(clang_getPointeeType(type)));
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
    json_value *unwrapped = unwrap_type(clang_Type_getNamedType(type));
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

  throw(&UnhandledTypeException, unwrap_string(clang_getTypeKindSpelling(type.kind)));
}

json_value *unwrap_function_args(CXCursor cursor) {
  json_value *args = json_array_new(0);
  int numArgs = clang_Cursor_getNumArguments(cursor);
  int i;

  for (i = 0; i < numArgs; ++i) {
    json_value *arg = json_object_new(0);
    CXCursor argCursor = clang_Cursor_getArgument(cursor, i);
    const char *argName = unwrap_string(clang_getCursorSpelling(argCursor));
    CXType argType = clang_getCursorType(argCursor);
    json_object_push(arg, "name", json_string_new(argName));
    json_object_push(arg, "type", unwrap_type(argType));
    json_array_push(args, arg);
  }

  return args;
}

json_value *visit_function(CXCursor cursor) {
  json_value *data = new_declaration(cursor, "function");
  CXType cxType = clang_getCursorType(cursor);
  CXType returnType = clang_getResultType(cxType);

  json_object_push(data, "returns", unwrap_type(returnType));
  json_object_push(data, "args", unwrap_function_args(cursor));
  json_object_push(data, "variadic", json_boolean_new(clang_isFunctionTypeVariadic(cxType)));

  return data;
}

enum CXVisitorResult struct_field_visitor(CXCursor cursor, CXClientData clientData) {
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

enum CXChildVisitResult visitor(CXCursor cursor, CXCursor parent, CXClientData clientData) {
  CXSourceLocation location = clang_getCursorLocation(cursor);
  if (!clang_Location_isFromMainFile(location)) return CXChildVisit_Continue;

  enum CXCursorKind cursorKind = clang_getCursorKind(cursor);
  json_value *state = *(json_value **)(clientData);

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

CXTranslationUnit parse_file(CXIndex *index, char *filename) {
  CXTranslationUnit tu = clang_createTranslationUnitFromSourceFile(
    *index,
    filename,
    0,
    clang_args,
    0,
    NULL
  );

  if (!tu) {
    throw(&UnparseableFileException, filename);
  }

  return tu;
}

WalkerResult *walk_clang_ast(char *header_filename) {
  json_value *state = json_array_new(0);
  WalkerResult *result = (WalkerResult *)malloc(sizeof(WalkerResult));
  CXIndex index = clang_createIndex(0, 1);
  CXTranslationUnit tu;

  try {
    tu = parse_file(&index, header_filename);
    CXCursor rootCursor = clang_getTranslationUnitCursor(tu);
    clang_visitChildren(rootCursor, visitor, &state);

    char *json_buf = malloc(json_measure(state));
    json_serialize(json_buf, state);
    result->status = WalkerStatus_OK;
    result->data = json_buf;
  }
  catch {
    result->status = WalkerStatus_Error;
    result->data = get_exception_message();
  }
  finally {
    if (tu) clang_disposeTranslationUnit(tu);
    clang_disposeIndex(index);
    json_builder_free(state);
  }

  return result;
}
