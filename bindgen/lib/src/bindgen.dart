import 'dart:io';
import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:bindgen/src/exception.dart';
import 'package:bindgen/loaders/loader.dart';
import 'package:bindgen/src/parser.dart';
import 'package:bindgen/src/library.dart';

final _argParser = ArgParser()
  ..addOption('loader', abbr: 'l', help: 'The loader to read the header file with (defaults to clang)')
  ..addOption('name', abbr: 'n', help: 'The name of the library to be generated (defaults to the header filename)')
  ..addOption('output', abbr: 'o', help: 'The file to output the generated library to (defaults to the library name in the current directory)')
  ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Whether or not to print debug info')
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Print this help message');

String _helpText() {
  var sb = StringBuffer()..writeln();
  sb.writeln('dart_bindgen: Generate Dart FFI bindings for C libraries');
  sb.writeln();
  sb.writeln('Usage: <script> <options> /path/to/header/file');
  sb.writeln();
  sb.writeln('Options:');
  sb.writeln(_argParser.usage);

  return sb.toString();
}

class Bindgen {
  static final String helpText = _helpText();

  static ArgResults parseArguments(List<String> arguments) => _argParser.parse(arguments);

  const Bindgen({
    @required this.filePath,
    @required this.libraryName,
    @required this.load,
    this.verbose = false,
    @required this.outputFilePath,
  });

  factory Bindgen.fromArguments(ArgResults args) {
    final paths = args.rest;
    if (paths.length != 1) {
      throw BindgenException('Please pass a path to a single header file');
    }

    var libraryName = args['name'] ?? path.basenameWithoutExtension(paths.first);

    return Bindgen(
      filePath: path.absolute(paths.first),
      libraryName: libraryName,
      load: Loader.get(args['loader'] ?? 'clang'),
      verbose: args['verbose'] as bool,
      outputFilePath: args['output'] ?? libraryName + '.g.dart',
    );
  }

  final String filePath;
  final String libraryName;
  final Loader load;
  final bool verbose;
  final String outputFilePath;

  Future<void> run() async {
    await load.init();
    final parse = Parser(verbose: verbose);
    var json = await load(filePath);
    var lib = Library(name: libraryName, members: parse(json));
    try {
      await File(outputFilePath).writeAsString(lib.toDart());
    }
    on FileSystemException catch (e) {
      throw BindgenException.onOutput(e);
    }
  }
}
