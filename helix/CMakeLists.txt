cmake_minimum_required (VERSION 2.6)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "/usr/local/lib/cmake")
project(helix)
set(PROJECT_VERSION "0.0.1")

#set(OpenCV_DIR "/usr/local/opt/opencv/share/OpenCV")
find_package(OpenCV REQUIRED)
find_package(Boost COMPONENTS system thread chrono program_options REQUIRED)
find_package(aruco REQUIRED)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

set(all_libs ${OpenCV_LIBS} ${aruco_LIBS} ${Boost_LIBRARIES})

# START EDITING
set(ext_libs nlopt matio hdf5)
set(my_libs flexvideo watcher processor fitter graphics writer geometry)
set(my_bins acquire test_geometry)
file(GLOB my_stuff *.yml)
# END EDITING

add_definitions( -DSHARE_PREFIX="${CMAKE_INSTALL_PREFIX}/share" )

foreach(lib ${my_libs})
    add_library(${lib} ${lib}.cpp)
endforeach(lib)

foreach(bin ${my_bins})
    add_executable(${bin} ${bin}.cpp)
    target_link_libraries(${bin} ${my_libs} ${ext_libs} ${all_libs})
endforeach(bin)

install(TARGETS ${my_bins} DESTINATION bin)
install(TARGETS ${my_libs} DESTINATION lib)
install(FILES ${my_stuff} DESTINATION share)

