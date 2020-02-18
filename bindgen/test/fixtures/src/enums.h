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

enum FromOne {
  one = 1,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten
};

enum NetWorth {
  thousand = 1000,
  million = thousand * 1000,
  billion = million * 1000,
  trillion = billion * 1000L,
};

enum Status {
  error = -2,
  success = 0,
  warning = -1,
};
