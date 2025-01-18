package main

import "vendor:miniaudio"
OPENGL_MAJOR :: 4
OPENGL_MINOR :: 6
import "base:runtime"
import "camera"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:time"
import "draw"
import "gs"
import "shader"
import gl "vendor:OpenGL"
import "vendor:glfw"
c: camera.Camera = camera.new()

lastCubePlaced: f64 = -1
main :: proc() {
	// when ODIN_DEBUG {
	// 	track: mem.Tracking_Allocator
	// 	mem.tracking_allocator_init(&track, context.allocator)
	// 	context.allocator = mem.tracking_allocator(&track)

	// 	defer {
	// 		if len(track.allocation_map) > 0 {
	// 			fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
	// 			for _, entry in track.allocation_map {
	// 				fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
	// 			}
	// 		}
	// 		if len(track.bad_free_array) > 0 {
	// 			fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
	// 			for entry in track.bad_free_array {
	// 				fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
	// 			}
	// 		}
	// 		mem.tracking_allocator_destroy(&track)
	// 	}
	// }

	glfwInit()

	using gs

	draw.initCube()
	defer draw.cleanup()
	// Render loop
	lastCubePlaced = glfw.GetTime()


	gridWidth :: 10
	gridHeight :: 10
	cubes := [gridHeight * gridWidth]draw.Cube{}


	for x in 0 ..< gridWidth {
		for z in 0 ..< gridHeight {
			index := z * gridWidth + x
			cubes[index] = draw.Cube {
				color = {}, // Default color
				pos   = {f32(x) - gridWidth / 2, -1, f32(z) - gridHeight / 2},
			}
		}
	}
	// assert(len(cubes) == 1, fmt.aprintf("len of cubes is actually %d", len(cubes)))
	draw.addCubes(cubes[:])


	lastFrame = time.now()
	for !glfw.WindowShouldClose(window) {

		currentFrame := time.now()
		deltaTime = f32(time.duration_seconds(time.since(lastFrame)))
		lastFrame = currentFrame


		// if (startTime - lastCubePlaced) >= 0.5 {
		// 	draw.addCube({pos = {rand.float32() * 4, 1, rand.float32() * 4}, color = {0, 0, 0}})
		// 	lastCubePlaced = startTime
		// }
		processKeyboardInput(window)

		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.CULL_FACE)
		gl.CullFace(gl.BACK)
		gl.FrontFace(gl.CW) // or gl.CW depending on your winding order

		//TODO: remove this ductape. there should be a global way to set the needed camera uniforms
		gl.UseProgram(draw.cp.program)

		camera.frameUpdate(&c, draw.cp.program)

		draw.drawCubes()

		glfw.SwapBuffers(window)
		glfw.PollEvents()

		actualDeltaTime := time.duration_seconds(time.since(currentFrame))
		if actualDeltaTime < FRAME_DURATION {
			remaining := FRAME_DURATION - actualDeltaTime
			time.sleep(time.Duration(remaining * f64(time.Second)))
		}
	}


}

glfwInit :: proc() {
	using gs

	assert(glfw.Init() == true)

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, OPENGL_MAJOR)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, OPENGL_MINOR)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	glfw.WindowHint(glfw.OPENGL_DEBUG_CONTEXT, 1)


	when ODIN_OS == .Darwin {
		glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, 1)
	}

	gs.window = glfw.CreateWindow(SCR_WIDTH, SCR_HEIGHT, "Vexor", nil, nil)
	assert(window != nil)

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1)

	gl.load_up_to(OPENGL_MAJOR, OPENGL_MINOR, glfw.gl_set_proc_address)
	glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)

	glfw.SetCursorPosCallback(window, mouseCallback)
	gl.Enable(gl.DEPTH_TEST)
	enableGlDebug()

}
glfwClean :: proc() {
	using gs

	assert(window != nil)
	glfw.DestroyWindow(window)
	glfw.Terminate()

}
lastX: f64 = 0
lastY: f64 = 0
direction: vec3
yaw: f32 = -90.0
pitch: f32 = 0
firstMouse := true

mouseCallback :: proc "c" (window: glfw.WindowHandle, xPos: f64, yPos: f64) {

	if firstMouse {
		lastX = xPos
		lastY = yPos
		firstMouse = false
		// return
	}

	xOffset: f32 = f32(xPos - lastX)
	yOffset: f32 = f32(lastY - yPos)

	lastX = xPos
	lastY = yPos
	context = runtime.default_context()
	camera.processMouseMovement(&c, xOffset, yOffset)
}
processKeyboardInput :: proc(window: glfw.WindowHandle) {
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}
	camera.processKeyboard(&c)


}
