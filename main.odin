package main
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
import "vendor:fontstash"
import ui "vendor:microui"
import "vendor:miniaudio"
import "vendor:nanovg"
import nvg "vendor:nanovg/gl"
import sdl "vendor:sdl2"

OPENGL_MAJOR :: 4
OPENGL_MINOR :: 6

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
uiCtx: ui.Context

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


	gridWidth :: 20
	gridHeight :: 20
	cubes := [gridHeight * gridWidth]draw.Cube{}


	for x in 0 ..< gridWidth {
		for z in 0 ..< gridHeight {
			index := z * gridWidth + x
			cubes[index] = draw.Cube {
				color = {rand.float32() * 255, rand.float32() * 255, rand.float32() * 255}, // Default color
				pos   = {f32(x) - gridWidth / 2, -2, f32(z) - gridHeight / 2},
				mass  = 1,
			}
		}
	}
	// assert(len(cubes) == 1, fmt.aprintf("len of cubes is actually %d", len(cubes)))
	draw.addCubes(cubes[:])

	draw.addCube({pos = {1, 20, 1}, color = {255, 255, 255}, mass = 1})
	lastFrame = time.now()
	running := true
	gl.Enable(gl.CULL_FACE)
	gl.CullFace(gl.BACK)

	gl.FrontFace(gl.CW)
	for running {
		defer free_all(context.temp_allocator)

		currentFrame := time.now()
		deltaTime = f32(time.duration_seconds(time.since(lastFrame)))
		lastFrame = currentFrame

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
		draw.updateDrawings()

		// physics.applyGravity(&player, player.camera.pos)
		// player.camera.pos += physics.applyKinematics(&player, player.camera.pos, deltaTime)
		// player.camera.pos.y = max(player.camera.pos.y, 0)


		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)


		//TODO: remove this ductape. there should be a global way to set the needed camera uniforms
		gl.UseProgram(draw.cp.program)

		camera.frameUpdate(&player.camera, draw.cp.program)
		draw.drawCubes()

		// ui.begin(&uiCtx)

		// uiCtx.text_width = ui.default_atlas_text_width
		// uiCtx.text_height = ui.default_atlas_text_height
		// ui.text(&uiCtx, "hello world")
		// draw.drawText("hello world", 400, 200)
		// gl.ActiveTexture(gl.TEXTURE0)
		// gl.BindTexture(gl.TEXTURE_2D, texture)

		// gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
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

	assert(sdl.Init(sdl.INIT_VIDEO) == 0)

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

	vgCtx = nvg.Create({.ANTI_ALIAS, .STENCIL_STROKES})
	fontId := nanovg.CreateFont(vgCtx, "Arial", "resources/fonts/Arial.ttf")

	assert(fontId >= 0, "font creation failed")
	assert(vgCtx != nil)
	enableGlDebug()
}
sdlClean :: proc() {
	using gs
	assert(window != nil)
	if vgCtx != nil do nanovg.DeleteInternal(vgCtx)

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
