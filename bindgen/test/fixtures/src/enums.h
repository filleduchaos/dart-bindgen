enum Color {
  red,
  orange,
  yellow,
  green,
  blue,
  indigo,
  violet,
};

enum Namespaced {
  Namespaced_foo,
  Namespaced_bar,
  Namespaced_baz,
  Namespaced_quuz,
};

enum DataType {
  Char = 8,
  Short = 16,
  Int = 32,
  Long = 64,
};

enum NetWorth {
  thousand = 1000L,
  million = thousand * 1000L,
  billion = million * 1000L,
  trillion = billion * 1000L,
};

enum Status {
  error = -2,
  success = 0,
  warning = -1,
};

int is_green(enum Color color);
int is_foo(enum Namespaced placeholder);
int can_hold_24_bits(enum DataType type);
int is_billionaire(enum NetWorth netWorth);
int failed(enum Status status);

enum Color get_color(int wavelength);
