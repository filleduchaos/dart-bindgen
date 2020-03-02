import 'dart:math' as math;
import 'package:meta/meta.dart';

typedef CodeWriter = void Function(CodeBuffer);

enum CodeIndent {
  two,
  four,
  tab,
}

extension CodeIndentString on CodeIndent {
  static const indents = {
    CodeIndent.two: '  ',
    CodeIndent.four: '    ',
    CodeIndent.tab: '\t',
  };

  String asString() {
    return indents[this];
  }
}

class CodeBuffer {
  CodeBuffer({ this.indent = CodeIndent.two });

  final _buf = StringBuffer();
  final CodeIndent indent;
  var _blockLevel = 0;

  void assertTopLevel() {
    assert(_blockLevel == 0, 'Can only add classes/typedefs at the top level of a source file');
  }

  void addImport(String uri, { String as = '', String show = '' }) {
    assert(uri.isNotEmpty);
    var import = "import '$uri'";
    if (as.isNotEmpty) import += ' as $as';
    if (show.isNotEmpty) import += ' show $show';
    _buf.writeln('$import;');
  }

  void addLine([String line = '']) {
    if (line.isNotEmpty) _addIndent();
    _buf.writeln(line);
  }

  void addSpacedLine(String line) {
    addLine(line);
    addLine();
  }

  void addClass(String name, { String parent = '', @required CodeWriter builder }) {
    assertTopLevel();

    _buf.write('class $name');
    if (parent.isNotEmpty) _buf.write(' extends $parent');
    openBlock();
    builder(this);
    closeBlock();
  }

  void addEnum(String name, { @required Iterable<String> constants }) {
    assertTopLevel();

    _buf.write('enum $name');
    openBlock();
    for (var constant in constants) {
      addLine('$constant,');
    }
    closeBlock();
  }

  void addGetter(String name, { @required String type, @required String expression }) {
    addLine('$type get $name => $expression;');
  }

  void addSetter(String name, { @required String type, @required String expression }) {
    addLine('set $name($type value) => $expression;');
  }

  void addFunction(String name, {
    String returns = 'void',
    Iterable<String> typeParams = const [],
    Iterable<String> args = const [],
    bool override = false,
    bool static = false,
    CodeWriter builder,
    String expression,
  }) {
    assert((builder == null) ^ (expression == null));

    if (override) addLine('@override');
    _addIndent();
    if (static) _buf.write('static ');
    _buf.write('$returns $name');
    if (typeParams.isNotEmpty) _buf.write("<${typeParams.join(', ')}>");
    _buf.write("(${args.join(', ')})");

    if (expression != null) {
      _buf.write(' => $expression;\n');
    }
    else {
      openBlock();
      builder(this);
      closeBlock();
    }
  }

  void openBlock([ String statement = '' ]) {
    if (statement.isNotEmpty) _addIndent();
    _buf.write('$statement {\n');
    _blockLevel++;
  }

  void closeBlock({ bool addLine = false }) {
    _blockLevel--;
    this.addLine('}');
    if (addLine) this.addLine();
  }

  void addArray(String name, List<String> items, { int perLine = 10 }) {
    _addIndent();
    _buf..write(name)..write(' = [\n');

    for (var i = 0; i < items.length; i += perLine) {    
      var end = math.min(i + perLine, items.length);
      _addIndent();
      _buf..writeAll(items.sublist(i,end), ', ')..write(',\n');
    }

    addLine('];');
  }

  void _addIndent() {
    _buf.writeAll(List.generate(_blockLevel, (_) => indent.asString()));
  }

  void clear() {
    _buf.clear();
    _blockLevel = 0;
  }

  @override
  String toString() {
    return _buf.toString();
  }
}
