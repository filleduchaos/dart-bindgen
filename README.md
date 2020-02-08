# dart-bindgen

An experimental library/tool for generating Dart interfaces to C or C ABI compatible code from header files.

The aim of this project is to make it less tedious to use `dart:ffi` especially with existing libraries, in a way that's configurable/extensible from Dart. The author is also exploring implementing a Dart backend for [Swig](https://github.com/swig/swig) as `dart:ffi` becomes more mature.

Currently it relies exclusively on libclang, although it's fairly easy to implement support for another compiler/format.

**Warning:** This library is currently in a very pre-alpha state. You can check the [first release label](https://github.com/filleduchaos/dart_bindgen/labels/0.1.0) for work that's in progress for and/or blocking the 0.1.0 release.

## Usage

Currently to use this project you have to clone and build it yourself. You will have to have CMake (minimum 3.7) and Clang (including libclang) installed.

- Run `git clone --recurse-submodules <repo_path>` (there are a couple of C dependencies added as submodules).
- Build the Clang bindgen plugin:

```bash
cd clang_plugin
mkdir build && cd build
cmake -S .
make && make install
```

- Now you can use the tool by running `dart bin/bindgen.dart` from the `bindgen` folder.

```text
dart bin/bindgen.dart --help

dart_bindgen: Generate Dart FFI bindings for C libraries

Usage: <script> <options> /path/to/header/file

Options:
-l, --loader     The loader to read the header file with (defaults to "clang")
-n, --name       The name of the library to be generated (defaults to the header filename)
-o, --output     The file to output the generated library to (defaults to the library name in the current directory)
-v, --verbose    Whether or not to print debug info
-h, --help       Print this help message
```
