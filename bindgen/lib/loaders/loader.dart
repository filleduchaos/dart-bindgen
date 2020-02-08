import 'dart:async';
import 'package:bindgen/src/exception.dart';

abstract class Loader {
  const Loader();

  FutureOr<void> init();

  FutureOr<List> call(String path);

  static final Map<String, Loader> _loaders = {};

  static void register(String name, Loader loader) {
    if (_loaders[name] != null) {
      throw BindgenException('Already registered loader with name $name.');
    }

    _loaders[name] = loader;
  }

  static Loader get(String name) {
    var loader = _loaders[name];
    if (loader != null) return loader;

    throw BindgenException('Could not find loader with name $name: make sure you register it first.');
  }
}
