cmake_minimum_required (VERSION 2.6)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "/usr/local/lib/cmake")
project(helix)
set(PROJECT_VERSION "0.0.1")

#set(OpenCV_DIR "/usr/local/opt/opencv/share/OpenCV")
find_package(OpenCV REQUIRED)
find_package(Boost COMPONENTS system thread REQUIRED)
find_package(aruco REQUIRED)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

set(all_libs ${OpenCV_LIBS} ${aruco_LIBS} ${Boost_LIBRARIES})

add_library(flexvideo flexvideo.cpp)
add_library(watcher watcher.cpp)
add_library(processor processor.cpp)
add_library(graphics graphics.cpp)
add_library(writer writer.cpp)

add_executable(acquire acquire.cpp)
target_link_libraries(acquire watcher processor graphics writer flexvideo ${all_libs})

