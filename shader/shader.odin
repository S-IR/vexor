package shader

import "core:fmt"
import gl "vendor:OpenGL"
import "vendor:glfw"


createProgram :: proc(vertex_source, fragment_source: string) -> u32 {
	vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
	vertex_source_cstring := cstring(raw_data(vertex_source))
	gl.ShaderSource(vertex_shader, 1, &vertex_source_cstring, nil)
	gl.CompileShader(vertex_shader)
	checkShaderErrors(vertex_shader, "VERTEX")
	defer gl.DeleteShader(vertex_shader)

	fragment_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
	fragment_source_cstring := cstring(raw_data(fragment_source))
	gl.ShaderSource(fragment_shader, 1, &fragment_source_cstring, nil)
	gl.CompileShader(fragment_shader)
	checkShaderErrors(fragment_shader, "FRAGMENT")
	defer gl.DeleteShader(fragment_shader)

	program := gl.CreateProgram()
	gl.AttachShader(program, vertex_shader)
	gl.AttachShader(program, fragment_shader)
	gl.LinkProgram(program)
	checkProgramErrors(program)

	return program
}
checkShaderErrors :: proc(shader: u32, shader_type: string) {
	success: i32
	gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		info_log: [512]u8
		gl.GetShaderInfoLog(shader, 512, nil, &info_log[0])
		fmt.printf("ERROR::SHADER::%s::COMPILATION_FAILED\n%s\n", shader_type, string(info_log[:]))
	}
}
checkProgramErrors :: proc(program: u32) {
	success: i32
	gl.GetProgramiv(program, gl.LINK_STATUS, &success)
	if success == 0 {
		info_log: [512]u8
		gl.GetProgramInfoLog(program, 512, nil, &info_log[0])
		assert(
			false,
			fmt.aprintf("ERROR::SHADER::PROGRAM::LINKING_FAILED\n%s\n", string(info_log[:])),
		)

	}
}
