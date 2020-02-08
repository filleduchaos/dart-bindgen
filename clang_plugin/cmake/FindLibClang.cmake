set(LIBCLANG_KNOWN_VERSIONS 9.0.0 9.0 9
  8.0.1 8.0.0 8.0 8
  7.1.0 7.0.1 7.0.0 7.0 7
  6.0.1 6.0.0 6.0 6
  5.0.2 5.0.1 5.0.0 5.0 5
  4.0.1 4.0.0 4.0 4
  3.9.1 3.9.0 3.9
  3.8.1 3.8.0 3.8
  3.7.1 3.7.0 3.7)

set(libclang_header_search_paths)
set(libclang_lib_search_paths /usr/lib/llvm)

foreach (version ${LIBCLANG_KNOWN_VERSIONS})
  string(REPLACE "." "" undotted_version "${version}")
  set(libclang_versioned_paths
    "/usr/local/Cellar/llvm/${version}"
    "/opt/local/libexec/llvm-${version}"
    "/usr/local/lib/llvm-${version}"
    "/usr/local/llvm${undotted_version}"
    "/usr/lib/llvm-${version}"
    "/usr/lib/llvm/${version}"
  )
  foreach(libclang_path ${libclang_versioned_paths})
    list(APPEND libclang_header_search_paths "${libclang_path}/include")
    list(APPEND libclang_lib_search_paths "${libclang_path}/lib")
  endforeach()
endforeach()

find_path(LIBCLANG_INCLUDE_DIR clang-c/Index.h
  PATHS ${libclang_header_search_paths}
  PATH_SUFFIXES LLVM/include
  DOC "The directory containing clang-c/Index.h")

find_library(LIBCLANG_LIBRARY
  NAMES
    libclang.imp
    libclang
    clang
  PATHS ${libclang_lib_search_paths}
  PATH_SUFFIXES LLVM/lib
  DOC "The Clang shared library")

get_filename_component(LIBCLANG_LIBRARY_DIR ${LIBCLANG_LIBRARY} PATH)

set(LIBCLANG_LIBRARIES ${LIBCLANG_LIBRARY})
set(LIBCLANG_INCLUDE_DIRS ${LIBCLANG_INCLUDE_DIR})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LibClang DEFAULT_MSG
  LIBCLANG_LIBRARY LIBCLANG_INCLUDE_DIR)

mark_as_advanced(LIBCLANG_INCLUDE_DIR LIBCLANG_LIBRARY)
