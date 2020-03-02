#include "enums.h"

int is_green(enum Color color) {
  return color == green;
}

int is_foo(enum Namespaced placeholder) {
  return placeholder == Namespaced_foo;
}

int can_hold_24_bits(enum DataType type) {
  return (type == Int) || (type == Long);
}

int is_billionaire(enum NetWorth netWorth) {
  return netWorth == billion;
}

int failed(enum Status status) {
  return status == warning || status == error;
}

enum Color get_color(int wavelength) {
  if (wavelength > 635) return red;
  else if (wavelength > 590) return orange;
  else if (wavelength > 560) return yellow;
  else if (wavelength > 520) return green;
  else if (wavelength > 490) return blue;
  else if (wavelength > 450) return indigo;
  return violet;
}
