#include <stdlib.h>
#include <string.h>
#include <clang-c/Index.h>
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
