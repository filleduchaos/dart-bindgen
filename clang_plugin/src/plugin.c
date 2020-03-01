#include "exceptions.h"
#include "visitors/visitors.h"

const char *clang_args[] = {};

typedef enum WalkerStatus {
  WalkerStatus_OK = 0,
  WalkerStatus_Error = 1,
} WalkerStatus;

typedef struct WalkerResult {
  WalkerStatus status;
  const char *data;
} WalkerResult;

static CXTranslationUnit parse_file(CXIndex *index, char *filename) {
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
  CursorDeque *deque = new_cursor_deque();

  try {
    tu = parse_file(&index, header_filename);
    CXCursor rootCursor = clang_getTranslationUnitCursor(tu);
    traverse_root(rootCursor, deque);

    while (deque_has_cursors(deque)) {
      CXCursor cursor = pop_cursor(deque);
      json_value *declaration = visit_cursor(cursor, deque);
      if (declaration != NULL) json_array_push(state, declaration);
    }

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
    free_cursor_deque(deque);
    json_builder_free(state);
  }

  return result;
}
