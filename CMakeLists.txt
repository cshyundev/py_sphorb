# cmake_minimum_required(VERSION 3.12)
# project(py_sphorb)

# # Find pybind11 and OpenCV
# find_package(pybind11 REQUIRED)
# find_package(OpenCV REQUIRED)

# # Include directories
# include_directories(${OpenCV_INCLUDE_DIRS} include)

# # Ensure all source files are compiled with -fPIC
# set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# # Add source files for SPHORB and other dependencies
# add_library(SPHORB STATIC src/SPHORB.cpp src/detector.cpp src/pfm.cpp)

# # Build Python bindings
# add_library(sphorb_bindings MODULE src/sphorb_bindings.cpp)
# target_link_libraries(sphorb_bindings PRIVATE SPHORB ${OpenCV_LIBS} pybind11::module)

# # Set the output properties for the Python extension module
# set_target_properties(sphorb_bindings PROPERTIES PREFIX "${PYTHON_MODULE_PREFIX}" SUFFIX "${PYTHON_MODULE_EXTENSION}")

cmake_minimum_required(VERSION 3.12)
project(py_sphorb)

# Find pybind11 and OpenCV
find_package(pybind11 REQUIRED)
find_package(OpenCV REQUIRED)

# Include directories
include_directories(${OpenCV_INCLUDE_DIRS} include)

# Ensure all source files are compiled with -fPIC
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Add source files for SPHORB and other dependencies
add_library(SPHORB STATIC src/SPHORB.cpp src/detector.cpp src/pfm.cpp)

# Build Python bindings
add_library(sphorb_bindings MODULE src/sphorb_bindings.cpp)
target_link_libraries(sphorb_bindings PRIVATE SPHORB ${OpenCV_LIBS} pybind11::module)

# Set the output properties for the Python extension module
set_target_properties(sphorb_bindings PROPERTIES PREFIX "${PYTHON_MODULE_PREFIX}" SUFFIX "${PYTHON_MODULE_EXTENSION}")

# Add main.cpp for testing the SPHORB functionality
add_executable(sphorb_demo src/main.cpp)

# Link the SPHORB library and OpenCV to the executable
target_link_libraries(sphorb_demo PRIVATE SPHORB ${OpenCV_LIBS})
