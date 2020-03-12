#include <stdbool.h>
#include <stdlib.h>
#include <clang-c/Index.h>

void *checked_malloc(size_t size);

void *checked_realloc(void *ptr, size_t size);

char *concat_strings(const char *s1, const char *s2);

const char *unwrap_string(CXString cxStr);

typedef struct CursorNode CursorNode;

typedef struct CursorDeque CursorDeque;

CursorDeque *new_cursor_deque(void);

bool deque_has_cursors(CursorDeque *deque);

void push_cursor(CursorDeque *deque, CXCursor cursor);

void queue_cursor(CursorDeque *deque, CXCursor cursor);

CXCursor pop_cursor(CursorDeque *deque);

void free_cursor_deque(CursorDeque *deque);
