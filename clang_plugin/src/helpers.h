#include <stdbool.h>
#include <stdlib.h>
#include <clang-c/Index.h>

char *concat_strings(const char *s1, const char *s2);

const char *unwrap_string(CXString cxStr);

typedef struct {
  uint64_t *buffer;
  size_t capacity;
  size_t count;
} HashSet;

HashSet *new_hashset();

bool hashset_insert_key(HashSet *set, const char *key);

void free_hashset(HashSet *set);

typedef struct CursorNode {
  CXCursor data;
  struct CursorNode *prev;
  struct CursorNode *next;
} CursorNode;

typedef struct CursorDeque {
  CursorNode *front;
  CursorNode *back;
  HashSet *history;
} CursorDeque;

CursorDeque *new_cursor_deque(void);

bool deque_has_cursors(CursorDeque *deque);

void push_cursor(CursorDeque *deque, CXCursor cursor);

void queue_cursor(CursorDeque *deque, CXCursor cursor);

CXCursor pop_cursor(CursorDeque *deque);

void free_cursor_deque(CursorDeque *deque);
