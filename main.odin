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
import "core:mem"
import "core:time"
import "draw"
import "gs"
import "physics"
import "shader"
import gl "vendor:OpenGL"
import sdl "vendor:sdl2"


Player :: struct {
	using physics: physics.Physics,
	camera:        camera.Camera,
}


lastCubePlaced: f64 = -1
player := Player {
	camera = camera.new(),
	mass   = 1,
	iMass  = 1,
}
main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	// defer free(ptr)
	sdlInit()
	defer sdlClean()

	using gs

	draw.initCube()
	defer draw.cleanup()
	// Render loop
	lastCubePlaced = f64(sdl.GetTicks()) / 1000.0


	gridWidth :: 100
	gridHeight :: 100
	cubes := [gridHeight * gridWidth]draw.Cube{}


	for x in 0 ..< gridWidth {
		for z in 0 ..< gridHeight {
			index := z * gridWidth + x
			cubes[index] = draw.Cube {
				color = {rand.float32() * 255, rand.float32() * 255, rand.float32() * 255}, // Default color
				pos   = {f32(x) - gridWidth / 2, -1, f32(z) - gridHeight / 2},
			}
		}
	}
	// assert(len(cubes) == 1, fmt.aprintf("len of cubes is actually %d", len(cubes)))
	draw.addCubes(cubes[:])


	lastFrame = time.now()
	running := true
	for running {
		defer free_all(context.temp_allocator)

		currentFrame := time.now()
		deltaTime = f32(time.duration_seconds(time.since(lastFrame)))
		lastFrame = currentFrame


		// if (startTime - lastCubePlaced) >= 0.5 {
		// 	draw.addCube({pos = {rand.float32() * 4, 1, rand.float32() * 4}, color = {0, 0, 0}})
		// 	lastCubePlaced = startTime
		// }

		e: sdl.Event
		for sdl.PollEvent(&e) {
			#partial switch e.type {
			case .QUIT:
				running = false
			case .MOUSEMOTION:
				mouseMovement := cast(^sdl.MouseMotionEvent)&e
				handleMouseMotion(mouseMovement)
			case .KEYDOWN:
				keyEvent := cast(^sdl.KeyboardEvent)&e
				if keyEvent.keysym.sym == .ESCAPE {
					running = false
				}

			}
		}
		processKeyboardInput()
		physics.applyGravity(&player, player.camera.pos)
		player.camera.pos += physics.applyKinematics(&player, deltaTime)

		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.Enable(gl.CULL_FACE)
		gl.CullFace(gl.BACK)
		gl.FrontFace(gl.CW) // or gl.CW depending on your winding order

		//TODO: remove this ductape. there should be a global way to set the needed camera uniforms
		gl.UseProgram(draw.cp.program)

		camera.frameUpdate(&player.camera, draw.cp.program)
		draw.drawCubes()

		sdl.GL_SwapWindow(window)

		actualDeltaTime := time.duration_seconds(time.since(currentFrame))
		if actualDeltaTime < FRAME_DURATION {
			remaining := FRAME_DURATION - actualDeltaTime
			time.sleep(time.Duration(remaining * f64(time.Second)))
		}
	}


}

sdlInit :: proc() {
	using gs

	sdl.Init(sdl.INIT_VIDEO)

	sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, OPENGL_MAJOR)
	sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, OPENGL_MINOR)
	sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl.GLprofile.CORE))
	sdl.GL_SetAttribute(.DOUBLEBUFFER, 1)
	sdl.GL_SetAttribute(.DEPTH_SIZE, 24)

	window = sdl.CreateWindow(
		"Vexor",
		sdl.WINDOWPOS_CENTERED,
		sdl.WINDOWPOS_CENTERED,
		SCR_WIDTH,
		SCR_HEIGHT,
		{.OPENGL, .SHOWN},
	)
	assert(window != nil)

	gl_context := sdl.GL_CreateContext(window)
	assert(gl_context != nil)
	sdl.GL_MakeCurrent(window, gl_context)
	gl.load_up_to(OPENGL_MAJOR, OPENGL_MINOR, sdl.gl_set_proc_address)
	sdl.GL_SetSwapInterval(1) // Enable VSync

	// gl.load_up_to(OPENGL_MAJOR, OPENGL_MINOR, sdl.GL_GetProcAddress())
	sdl.SetRelativeMouseMode(true)

	gl.Enable(gl.DEPTH_TEST)
	enableGlDebug()
}
sdlClean :: proc() {
	using gs
	assert(window != nil)
	sdl.DestroyWindow(window)
	sdl.Quit()
}

lastX: f64 = 0
lastY: f64 = 0
direction: vec3
yaw: f32 = -90.0
pitch: f32 = 0
firstMouse := true

handleMouseMotion :: proc(event: ^sdl.MouseMotionEvent) {

	if firstMouse {
		lastX = f64(event.x)
		lastY = f64(event.y)
		firstMouse = false
		return
	}

	xOffset := f32(event.xrel)
	yOffset := -f32(event.yrel)

	camera.processMouseMovement(&player.camera, xOffset, yOffset)
}
processKeyboardInput :: proc() {
	keys := sdl.GetKeyboardState(nil)

	camera.processKeyboard(&player.camera)
}
