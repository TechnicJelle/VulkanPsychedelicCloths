cmake_minimum_required(VERSION 3.24)
project(VulkanPsychedelicCloths)

set(CMAKE_CXX_STANDARD 23)

# If no build type provided, assume Release mode
if (NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release)
endif ()

# If not Debug mode, set the NDEBUG macro
if (NOT CMAKE_BUILD_TYPE MATCHES Debug)
	add_definitions(-DNDEBUG)
endif ()

set(CMAKE_CXX_FLAGS_RELEASE "-Os")

find_package(Vulkan REQUIRED COMPONENTS glslc)

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
		COMMAND glslc ${VERT_IN} -o ${VERT_OUT} -O
)

## Fragment shader
set(FRAG_IN ${CMAKE_CURRENT_SOURCE_DIR}/shaders/shader.frag)
set(FRAG_OUT ${CMAKE_BINARY_DIR}/shaders/frag.spv)

add_custom_command(
		OUTPUT ${FRAG_OUT}
		DEPENDS ${FRAG_IN}
		COMMAND glslc ${FRAG_IN} -o ${FRAG_OUT} -O
)

add_executable(
		${PROJECT_NAME} src/main.cpp
		${VERT_OUT}
		${FRAG_OUT}
)

target_link_libraries(${PROJECT_NAME} Vulkan::Vulkan glfw)
