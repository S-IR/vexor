package draw

import "../gs"
import "../physics"
import "../shader"
import "base:runtime"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:mem"
import vmem "core:mem/virtual"
import gl "vendor:OpenGL"
import "vendor:glfw"
MAX_CUBES :: 1024 * 1024

Cube :: struct {
	using physics: physics.Physics,
	color:         vec3,
	pos:           vec3,
}

CubeProgram :: struct {
	program, vao, vbo, instanceVBO, colorVBO: u32,
	lastCubeIndex:                            i32,
	cubes:                                    [MAX_CUBES]Cube,
}


//cube program
cp: CubeProgram

initCube :: proc() {


	// cubeProgram = CubeProgram{}
	// cube, ok := cubeProgram.?
	// assert(ok)
	using cp
	program = shader.createProgram(shader.cubeVertexSource, shader.cubeFragmentSource)

	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)


	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(cubeVertices), &cubeVertices[0], gl.STATIC_DRAW)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), 0) //position
	gl.EnableVertexAttribArray(0)


	gl.GenBuffers(1, &cp.instanceVBO)
	gl.BindBuffer(gl.ARRAY_BUFFER, cp.instanceVBO)
	gl.BufferData(gl.ARRAY_BUFFER, MAX_CUBES * size_of(vec3), nil, gl.DYNAMIC_DRAW)
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(vec3), 0)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribDivisor(1, 1)

	gl.GenBuffers(1, &cp.colorVBO)
	gl.BindBuffer(gl.ARRAY_BUFFER, cp.colorVBO)
	gl.BufferData(gl.ARRAY_BUFFER, MAX_CUBES * size_of(vec3), nil, gl.DYNAMIC_DRAW)
	gl.VertexAttribPointer(2, 3, gl.FLOAT, gl.FALSE, size_of(vec3), 0)
	gl.EnableVertexAttribArray(2)
	gl.VertexAttribDivisor(2, 1)

	// cp.cubes[0] = Cube {
	// 	color = {0, 0, 0},
	// 	pos   = {-1, 0, 0},
	// }
	// cp.lastCubeIndex += 1

}
// drawCube :: proc(cube: Cube) {
// 	// cp, ok := cubeProgram.?
// 	// assert(ok)
// 	using cp

// 	// model := linalg.matrix4_rotate(math.to_radians(f32(glfw.GetTime())) * 90, vec3{0.5, 1.0, 0.0})

// 	model := linalg.matrix4_translate(cube.pos)
// 	gl.UseProgram(program)
// 	shader.programSet(program, "model", model)
// 	gl.BindVertexArray(vao)
// 	gl.DrawArrays(gl.TRIANGLES, 0, 36)

// }
addCube :: proc(cube: Cube) {
	assert(cp.lastCubeIndex < MAX_CUBES - 1)
	assert(cube.mass != 0)

	cp.cubes[cp.lastCubeIndex] = cube
	cp.lastCubeIndex += 1

	pos := cube.pos
	gl.BindVertexArray(cp.vao)


	gl.BindBuffer(gl.ARRAY_BUFFER, cp.instanceVBO)
	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		int(cp.lastCubeIndex - 1) * size_of(vec3),
		size_of(vec3),
		raw_data(pos[:]),
	)

	color := cube.color
	gl.BindBuffer(gl.ARRAY_BUFFER, cp.colorVBO)
	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		int(cp.lastCubeIndex - 1) * size_of(vec3),
		size_of(vec3),
		raw_data(color[:]),
	)
}

addCubes :: proc(cubes: []Cube) {
	prevIndex := cp.lastCubeIndex
	totalToAdd := i32(len(cubes))

	assert(prevIndex + totalToAdd <= MAX_CUBES, "Too many cubes to add!")

	copy(cp.cubes[prevIndex:prevIndex + totalToAdd], cubes)

	cp.lastCubeIndex += totalToAdd
	positions := make([]vec3, len(cubes), context.temp_allocator)
	colors := make([]vec3, len(cubes), context.temp_allocator)

	for cube, i in cubes {
		assert(cube.mass != 0)
		positions[i] = cube.pos
		colors[i] = linalg.normalize(cube.color)
	}

	gl.BindBuffer(gl.ARRAY_BUFFER, cp.instanceVBO)
	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		int(prevIndex * size_of(vec3)),
		int(totalToAdd * size_of(vec3)),
		raw_data(positions),
	)

	gl.BindBuffer(gl.ARRAY_BUFFER, cp.colorVBO)
	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		int(prevIndex * size_of(vec3)),
		int(totalToAdd * size_of(vec3)),
		raw_data(colors),
	)

}

updateDrawings :: proc() {
	for &cube in cp.cubes[:cp.lastCubeIndex] {
		physics.applyGravity(&cube, cube.pos)
		cube.pos += physics.applyKinematics(&cube, cube.pos, gs.deltaTime)
	}
	positions := make([]vec3, len(cp.cubes), context.temp_allocator)
	for cube, i in cp.cubes {
		positions[i] = cube.pos
	}

	gl.BindVertexArray(cp.vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, cp.instanceVBO)
	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		0,
		int(cp.lastCubeIndex * size_of(vec3)),
		raw_data(positions),
	)
}
drawCubes :: proc() {
	gl.UseProgram(cp.program)
	gl.BindVertexArray(cp.vao)
	gl.DrawArraysInstanced(gl.TRIANGLES, 0, 36, cp.lastCubeIndex)
}

cleanup :: proc() {
	gl.DeleteVertexArrays(1, &cp.vao)
	gl.DeleteBuffers(1, &cp.vbo)
	gl.DeleteBuffers(1, &cp.instanceVBO)
	gl.DeleteProgram(cp.program)

}
