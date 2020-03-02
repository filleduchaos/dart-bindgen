#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "booleans.h"

bool is_prime(uint32_t number) {
  if (number != 0 && number < 4) return true;

  uint32_t i;
  double root = sqrt((double) number);
  for (i = 2; i <= root; i++) { 
    if (number % i == 0) return false;
  }

  return true;
}

const char *greeting = "Hello, ";
const char *title = "Dr. ";

char *greet_doctor(char *name, bool use_title) {
  size_t length = strlen(greeting) + strlen(name) + 1;
  if (use_title) length += strlen(title);

  char *result = malloc(length);
  strcpy(result, greeting);
  if (use_title) strcat(result, title);
  strcat(result, name);

  return result;
}
