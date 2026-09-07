cmake_minimum_required(VERSION 3.16)
project(spotutil CXX)

# The Spot install to build against: SPOT_ROOT/include and SPOT_ROOT/lib (libspot.a, libbddx.a),
# the install_dir/usr/local that build_spot.sh produces.
set(SPOT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../install_dir/usr/local" CACHE PATH "Spot install prefix")
option(SPOTUTIL_STATIC "Link the executable statically (Linux)" ON)

add_executable(spotutil spotutil.cc)
set_target_properties(spotutil PROPERTIES CXX_STANDARD 20 CXX_STANDARD_REQUIRED ON)
target_include_directories(spotutil PRIVATE ${SPOT_ROOT}/include ${CMAKE_CURRENT_SOURCE_DIR})
target_link_directories(spotutil PRIVATE ${SPOT_ROOT}/lib)
target_link_libraries(spotutil PRIVATE spot bddx)
if(SPOTUTIL_STATIC AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
  target_link_options(spotutil PRIVATE -static)
endif()
