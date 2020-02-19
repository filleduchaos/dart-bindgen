cmake_minimum_required(VERSION 3.7 FATAL_ERROR)
project(clang_bindgen_plugin VERSION 0.1.0 LANGUAGES C)

set(CMAKE_INSTALL_PREFIX "${CMAKE_SOURCE_DIR}/../build")
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/")
set(CLANG_BINDGEN_SOURCES
  src/helpers.c
  src/exceptions.c
  src/visitors/enum.c
  src/visitors/function.c
  src/visitors/struct.c
  src/visitors/type.c
  src/visitors/visitor.c
  src/plugin.c
)

find_package(LibClang REQUIRED)
include_directories(${LIBCLANG_INCLUDE_DIRS} "${CMAKE_SOURCE_DIR}/deps/json-parser" "${CMAKE_SOURCE_DIR}/deps/json-builder")
link_directories(${LIBCLANG_LIBRARY_DIR})

add_subdirectory("${CMAKE_SOURCE_DIR}/deps/json-builder")

add_library(clang_bindgen_plugin SHARED ${CLANG_BINDGEN_SOURCES})
target_link_libraries(clang_bindgen_plugin PRIVATE clang jsonbuilder)

install (TARGETS clang_bindgen_plugin DESTINATION lib)
