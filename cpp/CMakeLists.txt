cmake_minimum_required (VERSION 2.6)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ".")
project (kinematic_arboretum)

set(OpenCV_DIR "/usr/local/opt/opencv/share/OpenCV")
find_package(OpenCV REQUIRED)
find_package(Boost COMPONENTS system thread REQUIRED)
message("boost libraries are at " ${Boost_LIBRARIES})

include_directories(../aruco/src)
link_directories(../aruco/src)

add_executable(aruco_tracker aruco_tracker.cpp)
target_link_libraries(aruco_tracker ${OpenCV_LIBS} aruco ${Boost_LIBRARIES})

