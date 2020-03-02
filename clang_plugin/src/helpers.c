#include <string.h>
#include "helpers.h"

char *concat_strings(const char *s1, const char *s2) {
  char *result = malloc(strlen(s1) + strlen(s2) + 1);
  strcpy(result, s1);
  strcat(result, s2);
  return result;
}

const char *unwrap_string(CXString cxStr) {
  const char *str = strdup(clang_getCString(cxStr));
  clang_disposeString(cxStr);
  return str;
};

typedef struct {
  uint64_t *buffer;
  size_t capacity;
  size_t count;
} HashSet;

size_t HashSet_Block_Capacity = 16;

HashSet *new_hashset() {
  HashSet *set = (HashSet *)malloc(sizeof(HashSet));
  set->buffer = (uint64_t *)malloc(HashSet_Block_Capacity * sizeof(uint64_t));
  set->capacity = HashSet_Block_Capacity;
  set->count = 0;
  return set;
}

// See https://en.wikipedia.org/wiki/Fowler_Noll_Vo_hash)
uint64_t FNV_64_PRIME = 1099511628211ULL;
uint64_t FNV_64_OFFSET = 14695981039346656037ULL;
static uint64_t fnv_1a_hash(const char *key) {
  size_t key_length = strlen(key);
  char *copy = malloc(key_length + 1);
  strcpy(copy, key);

  uint64_t hash = FNV_64_OFFSET;
  size_t i;
  for (i = 0; i < key_length; i++) {
    unsigned char c = copy[i];
    hash = (hash ^ c) * FNV_64_PRIME;
  }
  
  free(copy);
  return hash;
}

static bool hashset_contains(HashSet *set, uint64_t hash) {
  size_t i;
  for (i = 0; i < set->count; i++) {
    if (set->buffer[i] == hash) return true;
  }

  return false;
}

bool hashset_insert_key(HashSet *set, const char *key) {
  uint64_t hash = fnv_1a_hash(key);

  if (hashset_contains(set, hash)) return false;

  if (set->count == set->capacity) {
    set->capacity += HashSet_Block_Capacity;
    set->buffer = (uint64_t *)realloc(set->buffer, set->capacity * sizeof(uint64_t));
  }

  set->buffer[set->count] = hash;
  set->count += 1;
  return true;
}

void free_hashset(HashSet *set) {
  free(set->buffer);
  free(set);
}

struct CursorNode {
  CXCursor data;
  struct CursorNode *prev;
  struct CursorNode *next;
};

struct CursorDeque {
  CursorNode *front;
  CursorNode *back;
  HashSet *history;
};

static CursorNode *get_node_for(CursorDeque *deque, CXCursor cursor) {
  const char *key = unwrap_string(clang_getCursorSpelling(cursor));
  if (!hashset_insert_key(deque->history, key)) return NULL;

  CursorNode *node = (CursorNode *)malloc(sizeof(CursorNode));
  node->data = cursor;
  node->prev = node->next = NULL;
  return node;
}

CursorDeque *new_cursor_deque(void) {
  CursorDeque *deque = (CursorDeque *)malloc(sizeof(CursorDeque));
  deque->front = deque->back = NULL;
  deque->history = new_hashset();
  return deque;
}

bool deque_has_cursors(CursorDeque *deque) {
  return deque->front != NULL;
}

void push_cursor(CursorDeque *deque, CXCursor cursor) {
  CursorNode *node = get_node_for(deque, cursor);
  if (node == NULL) return;

  if (deque->front == NULL)
    deque->front = deque->back = node; 
  else { 
    node->next = deque->front;
    deque->front->prev = node;
    deque->front = node;
  }
}

void queue_cursor(CursorDeque *deque, CXCursor cursor) {
  CursorNode *node = get_node_for(deque, cursor);
  if (node == NULL) return;

  if (deque->back == NULL)
    deque->front = deque->back = node; 
  else { 
    node->prev = deque->back;
    deque->back->next = node;
    deque->back = node;
  }
}

CXCursor pop_cursor(CursorDeque *deque) {
  if (deque_has_cursors(deque)) {
    CursorNode *popped = deque->front;
    CXCursor cursor = popped->data;

    deque->front = deque->front->next;
    if (deque->front == NULL)
      deque->back = NULL;
    else
      deque->front->prev = NULL;

    free(popped);
    return cursor;
  }
}

void free_cursor_deque(CursorDeque *deque) {
  CursorNode *current = deque->front;

  while (current != NULL) {
    CursorNode *next = current->next;
    free(current);
    current = next;
  }

  free_hashset(deque->history);
  free(deque);
}
