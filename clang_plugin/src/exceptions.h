#include <stdbool.h>
#include <setjmp.h>

typedef struct Exception Exception;
typedef struct ExceptionType ExceptionType;
typedef const char *(*ExceptionFormatter)(Exception *);

struct Exception {
  const ExceptionType *type;
  const void *error_data;
};

struct ExceptionType {
  const char *name;
  const char *message_prefix;
  ExceptionFormatter format;
};

typedef enum ExecutionStage {
  ex_none,
  ex_trying,
  ex_throwing,
  ex_catching,
} ExecutionStage;

extern struct Context {
  jmp_buf error_thrown;
  ExecutionStage stage;
  Exception *exception;
} ExceptionContext;

void throw(const ExceptionType *type, const void *error_data);
const char *get_exception_message();

extern bool ex_try();
extern bool ex_catch();
extern bool ex_finally();


#define declare_exception(name) extern const ExceptionType name
#define define_exception(name, message_prefix, format) const ExceptionType name = { #name, message_prefix, format }
#define try if (ex_try() && setjmp(ExceptionContext.error_thrown) == 0)
#define catch else if (ex_catch())
#define finally if (ex_finally())

declare_exception(RuntimeException);
declare_exception(UnparseableFileException);
declare_exception(UnhandledDeclarationException);
declare_exception(InvalidTypeException);
declare_exception(UnhandledTypeException);
