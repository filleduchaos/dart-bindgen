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
