typedef struct Person {
  char *name;
  char *company;
  char *position;
} Person;

Person *create_person(char *name, char *company, char *position);
