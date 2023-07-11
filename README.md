# Vulkan Psychedelic Cloths
![1306 Lines of Code](https://img.shields.io/badge/Lines%20of%20Code-1306-blue)

A recreation of [my uni's OpenGL assignment](./3D Rendering Assignment.md) in Vulkan.

![demonstration GIF](.github/readme_assets/demo.gif)

## Controls
`1`: Switch to default view\
`2`: Switch to wireframe view\
`Mouse`: Shine light on the "cloths"

## Table of Contents
<!-- TOC -->
* [Vulkan Psychedelic Cloths](#vulkan-psychedelic-cloths)
  * [Controls](#controls)
  * [Table of Contents](#table-of-contents)
  * [Building and Running](#building-and-running)
    * [Linux](#linux)
      * [Mint](#mint)
      * [Arch](#arch)
    * [Windows](#windows)
  * [Development Log](#development-log)
    * [CMake Shader Compilation](#cmake-shader-compilation)
    * [Transfer Queue & Bit Masking](#transfer-queue--bit-masking)
    * [Close on Escape](#close-on-escape)
    * [Uniform Buffers: Descriptor Pool and Sets](#uniform-buffers-descriptor-pool-and-sets)
    * [Wireframe rendering](#wireframe-rendering)
    * [Assignment Excellent](#assignment-excellent)
  * [Time Spent](#time-spent)
<!-- TOC -->

## Building and Running
Instructions on how to build this project.

### Linux
#### Mint
(Debian and Ubuntu should be similar)
```bash
sudo apt update && sudo apt upgrade
sudo apt install git cmake g++ vulkan-tools libvulkan-dev vulkan-validationlayers-dev spirv-tools glslang-tools libglm-dev libglfw3-dev
git clone https://github.com/TechnicJelle/VulkanPsychedelicCloths.git
cd VulkanPsychedelicCloths
cmake -S . -B build
cmake --build build
cd build/
./VulkanPsychedelicCloths
```

#### Arch
(Other Arch-based distros should be similar)
```bash
sudo pacman -Syyuu
sudo pacman -S git cmake gcc make vulkan-devel glm glfw
git clone https://github.com/TechnicJelle/VulkanPsychedelicCloths.git
cd VulkanPsychedelicCloths
cmake -S . -B build
cmake --build build
cd build/
./VulkanPsychedelicCloths
```

### Windows
Try following this: https://vulkan-tutorial.com/Development_environment#page_Windows

## Development Log
A few "blog posts" about certain notable parts of the development.

I began by following the Vulkan Tutorial book (https://vulkan-tutorial.com/), but after finishing the chapter **Uniform Buffers**,
I had acquired the knowledge required to start going my own way; to start implementing the assignment requirements. 

### CMake Shader Compilation
During the chapter **Graphics Pipeline Basics: Shader Modules**, I went on a tangent regarding the compilation of the shaders,
which in the book is simply done with a script that you have to run every time you change something in the shader.\
I took the time to put the shader compilation into my CMake build setup, so every time the program itself gets built, it'll also build the shaders.
So there's no need for an external script somewhere anymore, because it's now fully integrated in the building of the program itself.\
It took a lot of time and effort, because CMake is quite a pain to work with, but in the end, I did do it, and I'm quite pleased with myself about it.

### Transfer Queue & Bit Masking
In the chapter **Vertex Buffers: Staging Buffer**, an optional challenge is given in the *Transfer Queue* paragraph. I usually skipped those, but this one felt doable, so I tried it.\
I managed to almost do it, but I got an error: "bad optional access", which I managed to track down to a single if-statement:
```cpp
if (queueFamily.queueFlags & !VK_QUEUE_GRAPHICS_BIT & VK_QUEUE_TRANSFER_BIT)
```
What happens here is part of a concept called "bit-masking", which I mostly do understand, but I have hardly any experience with it, so I had to ask for help on how to actually exactly do it.\
The code you see there is wrong, and this is the right code:
```cpp
if ((queueFamily.queueFlags & VK_QUEUE_TRANSFER_BIT) && !(queueFamily.queueFlags & VK_QUEUE_GRAPHICS_BIT))
```
I thought it was possible to combine bit masks like that, but it turns out that that is not the way it's done. You just do two checks.

After this, it still wouldn't work, which was due to a dumb mistake I had made somewhere else:
```cpp
struct QueueFamilyIndices {
	std::optional<uint32_t> graphicsFamily;
	std::optional<uint32_t> presentFamily;
	std::optional<uint32_t> transferFamily;
	
	bool isComplete() const {
		return graphicsFamily.has_value() && presentFamily.has_value();
	}
};
```
Can you spot it?

Exactly, I had simply forgotten to also include `transferFamily.has_value()`...\
After I included that, everything worked like it should! And I could continue working on the rest of the chapter, which then went without further troubles.

### Close on Escape
For little graphics programs like these, I'm used to being able to press `Esc` on my keyboard to close it. So I don't have to click the tiny X button.\
I took a little detour to refresh my knowledge of handling key presses with GLFW, which is the library I'm using to handle the creation of the window itself.\
It also handles the actual inputs, like the mouse, keyboard and even gamepads.
```cpp
void initWindow() {
	window = glfwCreateWindow(WIDTH, HEIGHT, "Vulkan Psychedelic Cloths", nullptr, nullptr);
	glfwSetKeyCallback(window, keyCallback);
}

static void keyCallback(GLFWwindow* window, int key, int scanCode, int action, int modifierKeys) {
	if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
		glfwSetWindowShouldClose(window, GLFW_TRUE);
	}
}
```
This ended up being all that's necessary.\
Just a simple custom handler function that I pass into GLFW to call whenever a key is pressed.

### Uniform Buffers: Descriptor Pool and Sets
After following that chapter from the book, I tried to run my program, but it kept logging an error to the console, meaning I had gone wrong somewhere.\
I could look at the answer code from the book, but I decided to try and debug it myself.\
Due to the validation layers Vulkan offers, it logged a very detailed error message about what went wrong, and where:
```
Validation Error: [ VUID-vkCmdDrawIndexed-None-02699 ] Object 0: handle = 0x301e6c0000000022, type = VK_OBJECT_TYPE_DESCRIPTOR_SET; | MessageID = 0xa44449d4
	Descriptor set VkDescriptorSet 0x301e6c0000000022[] encountered the following validation error at vkCmdDrawIndexed time:
	Descriptor in binding #0 index 0 is being used in draw but has never been updated via vkUpdateDescriptorSets() or a similar call.
	The Vulkan spec states: Descriptors in each bound descriptor set, specified via vkCmdBindDescriptorSets,
	must be valid as described by descriptor validity if they are statically used by the VkPipeline bound to the pipeline bind point used by this command
	(https://www.khronos.org/registry/vulkan/specs/1.3-khr-extensions/html/vkspec.html#VUID-vkCmdDrawIndexed-None-02699)
```
So I followed that log to where it pointed me to, which was the loop in which I update the Descriptor Sets[^1] for each frame currently in flight[^2].
```cpp
for (size_t i = 0; i < MAX_FRAMES_IN_FLIGHT; i++) {
	VkDescriptorBufferInfo bufferInfo {
		.buffer = uniformBuffers[i],
		.offset = 0,
		.range = sizeof(UniformBufferObject),
	};
	
	VkWriteDescriptorSet descriptorWrite {
		.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		.dstSet = descriptorSets[i],
		.dstBinding = 0,
		.dstArrayElement = 0,
		.descriptorCount = 1, // <-- I had forgotten this line
		.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
		.pBufferInfo = &bufferInfo,
	};
	
	vkUpdateDescriptorSets(device, 1, &descriptorWrite, 0, nullptr);
}
```
Luckily, it ended up just being a single part of the Write Descriptor Set object that I had forgotten.

[^1]: A Descriptor Set is a part of the Vulkan concept of Resource Descriptors, which are the way to send data to shaders that is _not_ different for each vertex, but the same everywhere.
[^2]: A Frame in Flight means a frame that is currently in the process of being rendered. In graphical applications, it is often good to have at least two frames in flight at any given time:
one that is being displayed on the screen, and another that is currently being drawn to. Then those can be swapped around when it's time for the screen to display the next frame.

### Wireframe rendering
![wireframe GIF](.github/readme_assets/devlog/wireframe.gif)

To make the planes warp and wobble around, it needs to have more than just the four vertices at each corner. It needs to have a whole bunch of vertices, which can then all be separately displaced.\
Such a plane can be generated with code, and for the 3D Rendering course I had already written a function for that.\
To debug it, though, I used the wireframe rendering feature of OpenGL.\
I went looking for a way to modify Vulkan's Render Pipeline, to toggle that option on and off. I found the option, but it's only possible to be set when the Pipeline is created.
Not after that, while the program is running. Vulkan's Render Pipeline is basically completely immutable, to encourage creating everything beforehand, and caching as much as possible.
(Source: https://computergraphics.stackexchange.com/questions/4499/how-to-change-sampler-pipeline-states-at-runtime-in-vulkan )\
So I went to search for a way to have multiple pipelines. Which I found, in the form of a GitHub repo full of examples of different Vulkan concepts.\
Specifically, this example: https://github.com/SaschaWillems/Vulkan/blob/master/examples/pipelines/pipelines.cpp \
This helped me understand how to use multiple pipelines, after which it was rather simple to create and store the multiple pipelines, and to switch between them on a button press.

The button presses are handled by GLFW, of course, so I had to expand the key callback function I described earlier to this:
```cpp
static void keyCallback(GLFWwindow* window, int key, int scanCode, int action, int modifierKeys) {
	PsychedelicClothsApplication* app = (PsychedelicClothsApplication*) (glfwGetWindowUserPointer(window));
	if (action != GLFW_PRESS) return;
	switch (key) {
		case GLFW_KEY_ESCAPE:
			glfwSetWindowShouldClose(window, GLFW_TRUE);
			break;
		case GLFW_KEY_1:
			app->currentPipeline = DEFAULT;
			break;
		case GLFW_KEY_2:
			app->currentPipeline = WIREFRAME;
			break;
		default:
			break;
	}
}
```
That first line of this function may look a little strange, so I'll explain it in a bit more detail:\
Due to the fact that the callback function is `static`, it can't access the `PsychedelicClothsApplication` class' member variables, so we need to get a pointer to it somehow.\
Luckily, GLFW allows us to store any pointer inside the window object, which we can then retrieve in the static context,
and convert back into a `PsychedelicClothsApplication*` type, so we can actually access and modify the class' member variables.\
I learnt this trick earlier while going through the book, here: https://vulkan-tutorial.com/Drawing_a_triangle/Swap_chain_recreation#page_Handling-resizes-explicitly , where it is used in the window resize callback.

### Assignment Excellent
For the other parts of the assignment, it was mostly enough to simply copy the shader code from my OpenGL assignment.\
Though for the excellent, that did not end up being enough.\
For some reason, the waving "cloth" did not wave properly. It seems to at first, but it did strange jumps and hops, which the OpenGL version most certainly did not do.

![vertices moving smoothly, but also jumping strangely sometimes](.github/readme_assets/devlog/vertex-noise-jumping.gif)

After about an hour or two of futile debugging of my own, I started looking up if Vulkan maybe had some extra debugging features I could use.\
Debugging shaders is always terribly difficult, because you can't just print out the values that it's calculating.\
But! Apparently there is a Vulkan extension that allows one to do just that!\
I looked into how to use it, and it seemed simple enough at first.\
But I never succeeded in getting it to output anything...\
I'm still not sure why, and I should look into this more sometime in the future, because this would be an insanely useful thing to have in my "tool belt".\
After another couple of hours, I thought to try to apply the noise calculations to the fragment shader, instead of the vertex shader, just to be able to see what it's doing a little better.\
And there it was. Very clear. Something was _definitely_ wrong with the noise function. The noise was not smooth in all places! It had some really nasty lines and seams in it.\
So I went looking for other noise functions, and I found many, one of which by the same author of the one I had been using already.\
I tried other ones first, but in the end, I decided to try that other one by that same author.\
The code was extremely similar, with the only real difference being in the hashing function that was used.\
Hashing functions are an integral part of pseudo-random number generator functions that take a number and give back another number. That output number is a very garbled result of the input.\
The real magic is when the input changes only a tiny bit, the output number changes drastically.\
The reason this is necessary, is because shaders don't have a nice built-in random number generator, so shader programmers have to supply their own. For most applications a simple calculation is good enough.
```glsl
float hash_old(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float hash_new(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.13);
	p3 += dot(p3, p3.yzx + 3.333);
	return fract((p3.x + p3.y) * p3.z);
}
```

![comparison between new hash function and the old one](.github/readme_assets/devlog/noise-new-vs-old.gif)

Using that new hashing function, the problem was gone! I am still so confused as to why that old hashing function works just fine in the OpenGL version, though.\
Now that the "cloths" were waving nice and smoothly, that officially meant I had finished the project! 🎉

## Time Spent
An activity prefixed with a "📖" means that that time was spent following a chapter of the book.

| Activity                                           | Hours |
|----------------------------------------------------|-------|
| Researching if I should learn Vulkan, and how      | 7     |
| 📖 Introduction, Overview, Development environment | 1     |
| 📖 Setup: Base code                                | 0.5   |
| 📖 Setup: Instance                                 | 1     |
| 📖 Setup: Validation Layers                        | 2     |
| 📖 Setup: Physical Devices and Queue Families      | 1.5   |
| 📖 Setup: Logical Device and Queues                | 1     |
| 📖 Presentation: Window Surface                    | 1     |
| 📖 Presentation: Swap Chain                        | 3     |
| 📖 Presentation: Image Views                       | 0.5   |
| 📖 Graphics Pipeline Basics: Introduction          | 0.5   |
| 📖 Graphics Pipeline Basics: Shader Modules        | 4     |
| 📖 Graphics Pipeline Basics: Fixed Functions       | 2     |
| 📖 Graphics Pipeline Basics: Render Passes         | 1     |
| 📖 Drawing: Framebuffers                           | 0.5   |
| 📖 Drawing: Command Buffers                        | 2     |
| 📖 Drawing: Rendering and Presentation             | 2     |
| 📖 Drawing: Frames in Flight                       | 1     |
| Close the program when you press Escape            | 0.5   |
| 📖 Drawing: Swap Chain Recreation                  | 2     |
| 📖 Vertex Buffers: Input Description               | 1     |
| 📖 Vertex Buffers: Buffer Creation                 | 3     |
| 📖 Vertex Buffers: Staging Buffer + Transfer Queue | 4     |
| 📖 Vertex Buffers: Index Buffer                    | 3     |
| 📖 Uniform Buffers: Descriptor Layout and Buffer   | 2     |
| 📖 Uniform Buffers: Descriptor Pool and Sets       | 3     |
| Two squares!                                       | 0.5   |
| Researching wireframe rendering                    | 3     |
| Implementing wireframe rendering                   | 2     |
| Experimenting with & implementing pipeline cache   | 4     |
| Procedural plane generation                        | 4     |
| Assignment **Average**                             | 4     |
| Assignment **Good**                                | 1     |
| Assignment **Excellent**                           | 5     |
| Writing the README.md                              | 5     |
| Writing the report                                 | 5     |
| **Total**                                          | 83.5  |
