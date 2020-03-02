import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:test/test.dart';
import 'generated_library.dart';
import '../test_helper.dart' show isE2E;

void main() {
  var libStructs = GeneratedLibrary('structs');

  group('structs', () {
    setUpAll(() async {
      await libStructs.build();
      await libStructs.load();
    });

    tearDownAll(libStructs.release);

    test('#createCoordinate creates and returns a pointer to a Coordinate struct', () {
      var Coordinate = libStructs.findStruct('Coordinate');

      var result = libStructs.call('createCoordinate', [6.52, 3.37]);
      expect(result, isA<Pointer<Struct>>());

      dynamic coordinate = (result as Pointer<Struct>).ref;
      expect(coordinate.runtimeType, equals(Coordinate));
      expect(coordinate.latitude, equals(6.52));
      expect(coordinate.longitude, equals(3.37));
    });
    
    test('#createPlace creates and returns a pointer to a Place struct', () {
      var Place = libStructs.findStruct('Place');
      var Coordinate = libStructs.findStruct('Coordinate');

      var result = libStructs.call('createPlace', ['Lagos', 6.52, 3.37]);
      expect(result, isA<Pointer<Struct>>());

      dynamic place = (result as Pointer<Struct>).ref;
      expect(place.runtimeType, equals(Place));
      expect(Utf8.fromUtf8(place.name), equals('Lagos'));

      dynamic coordinate = (place.coordinate as Pointer<Struct>).ref;
      expect(coordinate.runtimeType, equals(Coordinate));
      expect((coordinate as dynamic).latitude, equals(6.52));
      expect((coordinate as dynamic).longitude, equals(3.37));
    });

    test("#helloWorld returns the string 'Hello World'", () {
      var result = libStructs.call('helloWorld');

      expect(result, isA<String>());
      expect(result, equals('Hello World'));
    });

    test('#reverse reverses a given string', () {
      var string = '!xob eht ni kcaj';
      var result = libStructs.call('reverse', [string, string.length]);

      expect(result, isA<String>());
      expect(result, equals('jack in the box!'));
    });
  }, skip: !isE2E);
}
