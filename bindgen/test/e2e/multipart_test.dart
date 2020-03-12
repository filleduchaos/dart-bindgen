import 'dart:ffi';
import 'package:test/test.dart';
import 'generated_library.dart';
import '../test_helper.dart' show isE2E;

void main() {
  var libMulti = GeneratedLibrary('multipart');

  group('multipart', () {
    setUpAll(() async {
      await libMulti.build();
      await libMulti.load();
    });

    tearDownAll(libMulti.release);

    test('#reverseGeocode returns a pointer to an Address struct', () {
      var Address = libMulti.findStruct('Address');

      var result = libMulti.call('reverseGeocode', [37.4220, -122.0841]);
      expect(result, isA<Pointer<Struct>>());

      dynamic address = (result as Pointer<Struct>).ref;
      expect(address.runtimeType, equals(Address));
      expect(address.line1, equals('1600 Amphitheatre Parkway'));
      expect(address.city, equals('Mountain View'));
      expect(address.zip_code, equals('94043'));
      expect(address.state, equals('CA'));
    });

    test('#createPerson returns a pointer to a Person struct', () {
      var Person = libMulti.findStruct('Person');

      var result = libMulti.call('createPerson', ['Alice Bob', 'Inn Pho Sek', 'Forensic Computer Analyst']);
      expect(result, isA<Pointer<Struct>>());

      dynamic person = (result as Pointer<Struct>).ref;
      expect(person.runtimeType, equals(Person));
      expect(person.name, equals('Alice Bob'));
      expect(person.company, equals('Inn Pho Sek'));
      expect(person.position, equals('Forensic Computer Analyst'));
    });

    test("#getBio returns a Person's bio", () {
      var personPtr = libMulti.call('createPerson', ['Alice Bob', 'Inn Pho Sek', 'Forensic Computer Analyst']);

      var result = libMulti.call('getBio', [personPtr]);

      expect(result, isA<String>());
      expect(result, equals('Alice Bob (Forensic Computer Analyst at Inn Pho Sek)'));
    });
  }, skip: !isE2E);
}
