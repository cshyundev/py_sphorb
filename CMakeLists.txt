cmake_minimum_required(VERSION 3.15)
project(pysphorb)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(OpenCV REQUIRED)
find_package(pybind11 REQUIRED)

# Include directories
include_directories(${OpenCV_INCLUDE_DIRS})
include_directories(${CMAKE_CURRENT_SOURCE_DIR})

# Source files for SPHORB
set(SPHORB_SOURCES
    src/SPHORB.cpp
    src/utility.cpp
    src/detector.cpp
    src/nonmax.cpp
    src/pfm.cpp
)

# Create the Python module
pybind11_add_module(pysphorb
    src/sphorb_binding.cpp
    ${SPHORB_SOURCES}
)

# Link OpenCV libraries
target_link_libraries(pysphorb PRIVATE ${OpenCV_LIBS})

# Install the extension module (scikit-build-core will handle placement in wheel)
install(TARGETS pysphorb LIBRARY DESTINATION .)

# Install data files (maintaining src/Data structure)
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src/Data DESTINATION src)
