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

  void addClass(String name, { String parent = '', @required CodeWriter builder }) {
    assertTopLevel();

    _buf.write('class $name');
    if (parent.isNotEmpty) _buf.write(' extends $parent');
    openBlock();
    builder(this);
    closeBlock();
  }

  void addFunction(String name, {
    String returns = 'void',
    Iterable<String> typeParams = const [],
    Iterable<String> args = const [],
    @required CodeWriter builder,
  }) {
    _addIndent();
    _buf.write('$returns $name');
    if (typeParams.isNotEmpty) _buf.write("<${typeParams.join(', ')}>");
    _buf.write("(${args.join(', ')})");
    openBlock();
    builder(this);
    closeBlock();
  }

  void openBlock([ String statement = '' ]) {
    if (statement.isNotEmpty) _addIndent();
    _buf.write('$statement {\n');
    _blockLevel++;
  }

  void closeBlock() {
    _blockLevel--;
    addLine('}');
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
