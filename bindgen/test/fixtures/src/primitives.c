// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdlib.h>
#include <stdarg.h>
#include "primitives.h"

int sum(int a, int b) {
  return a + b;
}

int *multiply(int a, int b) {
  int *mult = (int *)malloc(sizeof(int));
  *mult = a * b;
  return mult;
}

int subtract(int *a, int b) {
  return *a - b;
}

int multi_sum(int nr_count, ...) {
  va_list nums;
  va_start(nums, nr_count);
  int sum = 0;
  for (int i = 0; i < nr_count; i++) {
    sum += va_arg(nums, int);
  }
  va_end(nums);
  return sum;
}
