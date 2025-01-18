package shader
import "core:fmt"
vec3 :: [3]f32
import gl "vendor:OpenGL"

programSetF32 :: proc(program: u32, name: cstring, value: f32) {
	assert(transmute(i32)program >= 0)
	loc := gl.GetUniformLocation(program, name)
	pF32 := value
	gl.Uniform1fv(loc, 1, &pF32)
}
programSetVec3 :: proc(program: u32, name: cstring, value: vec3) {
	assert(transmute(i32)program >= 0)
	loc := gl.GetUniformLocation(program, name)
	p := value
	gl.Uniform3fv(loc, 1, raw_data(&p))
}
programSetMatrix4 :: proc(program: u32, name: cstring, value: matrix[4, 4]f32) {
	assert(transmute(i32)program >= 0)
	loc := gl.GetUniformLocation(program, name)
	p := value
	gl.UniformMatrix4fv(loc, 1, false, raw_data(&p))
}
programSet :: proc {
	programSetF32,
	programSetVec3,
	programSetMatrix4,
}
