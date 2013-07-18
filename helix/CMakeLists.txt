cmake_minimum_required (VERSION 2.6)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "/usr/local/lib/cmake")

#set(OpenCV_DIR "/usr/local/opt/opencv/share/OpenCV")
find_package(OpenCV REQUIRED)
find_package(Boost COMPONENTS system thread REQUIRED)
find_package(aruco REQUIRED)

add_executable(acquire acquire.cpp)
target_link_libraries(acquire ${OpenCV_LIBS} ${aruco_LIBS} ${Boost_LIBRARIES})

