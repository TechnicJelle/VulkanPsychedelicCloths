cmake_minimum_required(VERSION 3.24)
project(Vulkan)

set(CMAKE_CXX_STANDARD 23)

# If no build type provided, assume Release mode
if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release)
endif()

# If not Debug mode, set the NDEBUG macro
if (NOT CMAKE_BUILD_TYPE MATCHES Debug)
	add_definitions(-DNDEBUG)
endif()

set(CMAKE_CXX_FLAGS_RELEASE "-Os")

find_package(Vulkan REQUIRED)

find_package(glfw3 3.3 REQUIRED)

add_executable(${PROJECT_NAME} src/main.cpp)

target_link_libraries(${PROJECT_NAME} Vulkan::Vulkan glfw)
