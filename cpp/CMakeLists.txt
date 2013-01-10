cmake_minimum_required (VERSION 2.6)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ".")
project (kinematic_arboretum)

find_package (OpenCV REQUIRED)

message (STATUS "opencv libs: " ${OpenCV_LIBS})

include_directories (aruco)
link_directories (aruco)

add_executable (aruco_tracker aruco_tracker.cpp)
target_link_libraries (aruco_tracker ${OpenCV_LIBS} aruco)

