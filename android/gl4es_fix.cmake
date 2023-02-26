
#include("$ENV{ANDROID_NDK}/build/cmake/android.toolchain.cmake")

set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)

set(CMAKE_SYSTEM_NAME "Linux")
unset(ANDROID)

add_definitions(-DANDROID=1)

macro(install)
	set(CMAKE_SYSTEM_NAME "Android")
	set(ANDROID)
endmacro(install)

macro(find_library)
	set(log-lib log)
endmacro(find_library)

#set(CMAKE_C_FLAGS $ENV{CFLAGS})

link_directories("${CMAKE_SOURCE_DIR}/../prebuilt/$ENV{ARCH}/lib")
include_directories("${CMAKE_SOURCE_DIR}/../prebuilt/$ENV{ARCH}/include")
include_directories("${CMAKE_SOURCE_DIR}/../prebuilt/$ENV{ARCH}/include/libdrm")
include_directories("${CMAKE_SOURCE_DIR}/../prebuilt/all/include")