#include <stdlib.h>
#include "helpers.h"
#include "exceptions.h"

struct Context ExceptionContext = {0};

void throw(const ExceptionType *type, const void *error_data) {
  Exception *exception = (Exception *)malloc(sizeof(Exception));
  exception->type = type;
  exception->error_data = error_data;
  ExceptionContext.exception = exception;
  ExceptionContext.stage = ex_throwing;
  longjmp(ExceptionContext.error_thrown, 1);
}

const char *get_exception_message() {
  if (ExceptionContext.stage == ex_catching) {
    ExceptionFormatter format = ExceptionContext.exception->type->format;
    const char *message = (*format)(ExceptionContext.exception);
    free(ExceptionContext.exception);
    ExceptionContext.exception = NULL;
    return message;
  }
  else {
    throw(&RuntimeException, "Cannot retrieve exception message outside a catch block");
  }
};

bool ex_try() {
  bool should_try = ExceptionContext.stage == ex_none;
  if (should_try) ExceptionContext.stage = ex_trying;

  return should_try;
}

bool ex_catch() {
  bool should_catch = ExceptionContext.stage == ex_throwing;
  if (should_catch) ExceptionContext.stage = ex_catching;

  return should_catch;
}

bool ex_finally() {
  bool should_finally = ExceptionContext.stage == ex_trying || ExceptionContext.stage == ex_catching;
  if (should_finally) ExceptionContext.stage = ex_none;

  return should_finally;
}

static const char *identity_formatter(Exception *exception) {
  return exception->type->message_prefix;
}

static const char *string_data_formatter(Exception *exception) {
  const ExceptionType *type = exception->type;
  return concat_strings(type->message_prefix, (const char *)(exception->error_data));
}

define_exception(RuntimeException, "", &string_data_formatter);
define_exception(UnparseableFileException, "Unable to parse the provided header file ", &string_data_formatter);
define_exception(UnhandledDeclarationException, "Encountered a declaration that can't yet be handled: ", &string_data_formatter);
define_exception(InvalidTypeException, "Encountered an invalid or unexposed type in an unexpected place", &identity_formatter);
define_exception(UnhandledTypeException, "Encountered a type that can't yet be handled: ", &string_data_formatter);
