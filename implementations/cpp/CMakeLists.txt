cmake_minimum_required(VERSION 3.14)
project(geographiclib_benchmark)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE Release)

find_package(GeographicLib REQUIRED)

add_executable(benchmark benchmark.cpp)
target_link_libraries(benchmark ${GeographicLib_LIBRARIES})
target_include_directories(benchmark PRIVATE ${GeographicLib_INCLUDE_DIRS})
