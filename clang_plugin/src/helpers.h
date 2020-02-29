#include <stdbool.h>
#include <clang-c/Index.h>

char *concat_strings(const char *s1, const char *s2);

const char *unwrap_string(CXString cxStr);

typedef struct {
  uint64_t *buffer;
  size_t capacity;
  size_t count;
} HashSet;

HashSet *new_hashset();

bool hashset_insert_key(HashSet *set, char *key);

void free_hashset(HashSet *set);
