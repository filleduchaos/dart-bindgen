typedef struct Address {
  char *line1;
  char *city;
  char *zip_code;
  char *state;
} Address;

Address *reverse_geocode(double latitude, double longitude);
