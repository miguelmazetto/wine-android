cmake_minimum_required(VERSION 3.10)
project(libgbm LANGUAGES C)

link_directories("${CMAKE_SOURCE_DIR}/../prebuilt/$ENV{ARCH}/lib")
include_directories("${CMAKE_SOURCE_DIR}/../prebuilt/$ENV{ARCH}/include")
include_directories("${CMAKE_SOURCE_DIR}/../prebuilt/$ENV{ARCH}/include/libdrm")
include_directories("${CMAKE_SOURCE_DIR}/../prebuilt/all/include")

add_definitions(-DDEFAULT_BACKENDS_PATH="./gbm")

add_library(gbm STATIC
	src/gbm.c
	src/backend.c
	src/gbm_abi_check.c
	)

target_link_libraries(gbm drm)