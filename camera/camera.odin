package camera

import "../gs"
import "../shader"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import glm "core:math/linalg/glsl"
import "vendor:glfw"

vec3 :: linalg.Vector3f32


Camera_Movement :: enum {
	FORWARD,
	BACKWARD,
	LEFT,
	RIGHT,
}

// Default camera values
DEFAULT_YAW: f32 = -90.0
DEFAULT_PITCH: f32 = 0.0
DEFAULT_SPEED: f32 = 2.5
DEFAULT_SENSITIVITY: f32 = 0.1
DEFAULT_ZOOM: f32 = 90.0

Camera :: struct {
	pos:               vec3,
	front:             vec3,
	up:                vec3,
	right:             vec3,
	worldUp:           vec3,
	yaw:               f32,
	pitch:             f32,
	movement_speed:    f32,
	mouse_sensitivity: f32,
	zoom:              f32,
}

new :: proc(
	pos: vec3 = {0.0, 0.0, 3},
	up: vec3 = {0.0, 1.0, 0.0},
	yaw: f32 = DEFAULT_YAW,
	pitch: f32 = DEFAULT_PITCH,
	front: vec3 = {0, 0, 0},
) -> Camera {
	c := Camera {
		front             = front,
		movement_speed    = DEFAULT_SPEED,
		mouse_sensitivity = DEFAULT_SENSITIVITY,
		zoom              = DEFAULT_ZOOM,
		pos               = pos,
		worldUp           = up,
		yaw               = yaw,
		pitch             = pitch,
	}
	updateVectors(&c)
	return c
}

processKeyboard :: proc(c: ^Camera) {
	using gs

	movementVector: vec3 = {}
	normalizedFront := linalg.normalize(c.front)
	normalizedRight := linalg.normalize(c.right)

	if glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS {
		movementVector += normalizedFront // Move forward
	}
	if glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS {
		movementVector -= normalizedFront // Move backward
	}
	if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS {
		movementVector -= normalizedRight // Move left
	}
	if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS {
		movementVector += normalizedRight // Move right
	}

	velocity := deltaTime * c.movement_speed

	// fmt.printf("vector : %v\n", movementVector)
	// fmt.printf("len : %v\n", linalg.length(movementVector))

	if linalg.length(movementVector) > 0 {
		c.pos += glm.normalize(movementVector) * velocity
	}
	// fmt.printf("c pos: %v\n", c.pos)


}
processMouseMovement :: proc(c: ^Camera, received_xOffset: f32, received_yOffset: f32) {
	xOffset := received_xOffset * c.mouse_sensitivity
	yOffset := received_yOffset * c.mouse_sensitivity

	c.yaw += xOffset
	c.pitch += yOffset

	if c.pitch > 89.0 do c.pitch = 89.0
	if c.pitch < -89.0 do c.pitch = -89.0
	updateVectors(c)

}
frameUpdate :: proc(using c: ^Camera, program: u32) {
	using gs
	projection := glm.mat4Perspective(glm.radians(c.zoom), SCR_WIDTH / SCR_HEIGHT, 0.1, 100)

	shader.programSet(program, "projection", projection)
	// projectionLoc := gl.GetUniformLocation(program, "projection")
	// gl.UniformMatrix4fv(projectionLoc, 1, false, raw_data(&projection))

	view := glm.mat4LookAt(c.pos, c.pos + c.front, c.up)
	shader.programSet(program, "view", view)
}
updateVectors :: proc(using c: ^Camera) {
	front = {}
	for i in c.pos {
		assert(!math.is_nan(i))
	}
	front.x = math.cos(glm.radians(yaw)) * math.cos(glm.radians(pitch))
	front.y = math.sin(glm.radians(pitch))
	front.z = math.sin(glm.radians(yaw)) * math.cos(glm.radians(pitch))
	front = glm.normalize(front)

	right = glm.normalize(glm.cross(front, worldUp))
	up = glm.normalize(glm.cross(right, front))


}
