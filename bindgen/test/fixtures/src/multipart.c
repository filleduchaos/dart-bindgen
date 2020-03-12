#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "multipart.h"

// Yeah yeah it's not real reverse geocoding
Address *reverse_geocode(double latitude, double longitude) {
  Address *address = malloc(sizeof(Address));
  address->line1 = "1600 Amphitheatre Parkway";
  address->city = "Mountain View";
  address->zip_code = "94043";
  address->state = "CA";

  return address;
}

Person *create_person(char *name, char *company, char *position) {
  Person *person = malloc(sizeof(Person));
  person->name = name;
  person->company = company;
  person->position = position;
  
  return person;
}

const char *get_bio(Person *person) {
  const char *bio = malloc(
    strlen(person->name) + strlen(person->company) + strlen(person->position) + 8
  );
  sprintf(bio, "%s (%s at %s)", person->name, person->position, person->company);

  return bio;
}
