cmake_minimum_required(VERSION 3.22)
project(VulkanPsychedelicCloths)

set(CMAKE_CXX_STANDARD 17)

# If no build type provided, assume Release mode
if (NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release)
endif ()

# If not Debug mode, set the NDEBUG macro
if (NOT CMAKE_BUILD_TYPE MATCHES Debug)
	add_definitions(-DNDEBUG)
endif ()

set(CMAKE_CXX_FLAGS_RELEASE "-Os")

find_package(Vulkan REQUIRED)

find_package(glfw3 3.3 REQUIRED)

# Compile shaders
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/shaders/)
# TODO: Reduce code duplication here
## Vertex shader
set(VERT_IN ${CMAKE_CURRENT_SOURCE_DIR}/shaders/shader.vert)
set(VERT_OUT ${CMAKE_BINARY_DIR}/shaders/vert.spv)

add_custom_command(
		OUTPUT ${VERT_OUT}
		DEPENDS ${VERT_IN}
		COMMAND glslangValidator --target-env vulkan1.0 -e main -o ${VERT_OUT} ${VERT_IN}
)

## Fragment shader
set(FRAG_IN ${CMAKE_CURRENT_SOURCE_DIR}/shaders/shader.frag)
set(FRAG_OUT ${CMAKE_BINARY_DIR}/shaders/frag.spv)

add_custom_command(
		OUTPUT ${FRAG_OUT}
		DEPENDS ${FRAG_IN}
		COMMAND glslangValidator --target-env vulkan1.0 -e main -o ${FRAG_OUT} ${FRAG_IN}
)

file(GLOB sources ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)

add_executable(${PROJECT_NAME}
		${sources}
		${VERT_OUT} ${FRAG_OUT}
)

target_link_libraries(${PROJECT_NAME} Vulkan::Vulkan glfw)
