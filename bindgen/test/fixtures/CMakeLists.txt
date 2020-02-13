project(bindgen_e2e_tests LANGUAGES C)

set(CMAKE_SKIP_INSTALL_ALL_DEPENDENCY true)
set(CMAKE_INSTALL_PREFIX "${CMAKE_SOURCE_DIR}")
set(FIXTURES hello primitives structs)

foreach (fixture ${FIXTURES})
  add_library(${fixture} SHARED "src/${fixture}.c")
endforeach()

install (TARGETS ${FIXTURES} DESTINATION lib OPTIONAL)
