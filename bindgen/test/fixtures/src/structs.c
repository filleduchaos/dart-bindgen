// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdlib.h>
#include "structs.h"

struct Coordinate *create_coordinate(double latitude, double longitude) {
  struct Coordinate *coordinate = (struct Coordinate *)malloc(sizeof(struct Coordinate));
  coordinate->latitude = latitude;
  coordinate->longitude = longitude;
  return coordinate;
}

struct Place *create_place(char *name, double latitude, double longitude) {
  struct Place *place = (struct Place *)malloc(sizeof(struct Place));
  place->name = name;
  place->coordinate = create_coordinate(latitude, longitude);
  return place;
}

char *hello_world() {
  return "Hello World";
}

char *reverse(char *str, int length) {
  char *reversed_str = (char *)malloc((length + 1) * sizeof(char));
  for (int i = 0; i < length; i++) {
    reversed_str[length - i - 1] = str[i];
  }
  reversed_str[length] = '\0';
  return reversed_str;
}