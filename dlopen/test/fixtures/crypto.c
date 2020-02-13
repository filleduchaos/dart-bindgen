// Example "drop-in" replacement for a library (and/or library shipped with
// the executable)
#include <stdio.h>

void ERR_load_crypto_strings() {}

void ERR_free_strings() {}
