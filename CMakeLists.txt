cmake_minimum_required(VERSION 3.4...3.18)
project(SPHORB_Project)

# C++ 표준 설정
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 필요한 패키지 찾기
find_package(OpenCV REQUIRED)
find_package(pybind11 REQUIRED)

# 포함 디렉토리 설정
include_directories(${OpenCV_INCLUDE_DIRS})

# 소스 파일 목록 설정
file(GLOB_RECURSE SOURCES "src/*.cpp")
list(REMOVE_ITEM SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/bindings.cpp)

# pybind11 모듈 추가
pybind11_add_module(sphorb_module MODULE src/bindings.cpp ${SOURCES})

# 타겟 포함 디렉토리 설정
target_include_directories(sphorb_module PRIVATE
    ${OpenCV_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# 라이브러리 링크
target_link_libraries(sphorb_module PRIVATE ${OpenCV_LIBS})

# 모듈 이름 변경 (필요한 경우)
set_target_properties(sphorb_module PROPERTIES PREFIX "")

# 라이브러리 출력 디렉토리 설정
set_target_properties(sphorb_module PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_LIBRARY_OUTPUT_DIRECTORY})
