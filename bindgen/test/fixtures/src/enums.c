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
