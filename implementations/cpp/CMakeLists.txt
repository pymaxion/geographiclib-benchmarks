cmake_minimum_required(VERSION 3.14)
project(geographiclib_benchmark)

# Use new Boost config-file package discovery instead of deprecated FindBoost (CMake 3.30+)
if(POLICY CMP0167)
    cmake_policy(SET CMP0167 NEW)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE Release)

# Try CMake config first, fall back to pkg-config
find_package(GeographicLib QUIET)
if(NOT GeographicLib_FOUND)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(GeographicLib REQUIRED IMPORTED_TARGET geographiclib)
    set(GEOGRAPHICLIB_TARGET PkgConfig::GeographicLib)
else()
    set(GEOGRAPHICLIB_TARGET ${GeographicLib_LIBRARIES})
endif()

find_package(Boost REQUIRED)

add_executable(benchmark benchmark.cpp)
target_link_libraries(benchmark ${GEOGRAPHICLIB_TARGET})
target_include_directories(benchmark PRIVATE ${Boost_INCLUDE_DIRS})

# Add GeographicLib include dirs if using pkg-config
if(NOT GeographicLib_FOUND)
    target_include_directories(benchmark PRIVATE ${GeographicLib_INCLUDE_DIRS})
endif()
