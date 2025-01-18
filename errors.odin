package main

import "base:runtime"
import "core:fmt"
import gl "vendor:OpenGL"

gl_debug_output :: proc "c" (
	source: u32,
	type_: u32,
	id: u32,
	severity: u32,
	length: i32,
	message: cstring,
	user_param: rawptr,
) {
	// Ignore non-significant error/warning codes
	if id == 131169 || id == 131185 || id == 131218 || id == 131204 || id == 131222 {
		return
	}
	if type_ == gl.DEBUG_TYPE_PERFORMANCE {
		return
	}
	context = runtime.default_context()

	fmt.println("---------------")
	fmt.printf("Debug message (%d): %s\n", id, string(message))

	source_str: string
	switch source {
	case gl.DEBUG_SOURCE_API:
		source_str = "Source: API"
	case gl.DEBUG_SOURCE_WINDOW_SYSTEM:
		source_str = "Source: Window System"
	case gl.DEBUG_SOURCE_SHADER_COMPILER:
		source_str = "Source: Shader Compiler"
	case gl.DEBUG_SOURCE_THIRD_PARTY:
		source_str = "Source: Third Party"
	case gl.DEBUG_SOURCE_APPLICATION:
		source_str = "Source: Application"
	case gl.DEBUG_SOURCE_OTHER:
		source_str = "Source: Other"
	case:
		source_str = "Source: Unknown"
	}
	fmt.println(source_str)

	type_str: string
	switch type_ {
	case gl.DEBUG_TYPE_ERROR:
		type_str = "Type: Error"
	case gl.DEBUG_TYPE_DEPRECATED_BEHAVIOR:
		type_str = "Type: Deprecated Behaviour"
	case gl.DEBUG_TYPE_UNDEFINED_BEHAVIOR:
		type_str = "Type: Undefined Behaviour"
	case gl.DEBUG_TYPE_PORTABILITY:
		type_str = "Type: Portability"
	case gl.DEBUG_TYPE_PERFORMANCE:
		type_str = "Type: Performance"
	case gl.DEBUG_TYPE_MARKER:
		type_str = "Type: Marker"
	case gl.DEBUG_TYPE_PUSH_GROUP:
		type_str = "Type: Push Group"
	case gl.DEBUG_TYPE_POP_GROUP:
		type_str = "Type: Pop Group"
	case gl.DEBUG_TYPE_OTHER:
		type_str = "Type: Other"
	case:
		type_str = "Type: Unknown"
	}
	fmt.println(type_str)

	isSevere := false
	severity_str: string
	switch severity {
	case gl.DEBUG_SEVERITY_HIGH:
		severity_str = "Severity: high"
		isSevere = true
	case gl.DEBUG_SEVERITY_MEDIUM:
		severity_str = "Severity: medium"
		isSevere = true

	case gl.DEBUG_SEVERITY_LOW:
		severity_str = "Severity: low"
	case gl.DEBUG_SEVERITY_NOTIFICATION:
		severity_str = "Severity: notification"
	case:
		severity_str = "Severity: unknown"
	}
	fmt.println(severity_str)

	if isSevere {
		assert(false, severity_str)
	} else {
		fmt.println(severity_str)
	}

}

enableGlDebug :: proc() {
	gl.Enable(gl.DEBUG_OUTPUT)
	gl.Enable(gl.DEBUG_OUTPUT_SYNCHRONOUS)
	gl.DebugMessageCallback(gl_debug_output, nil)
	gl.DebugMessageControl(gl.DONT_CARE, gl.DONT_CARE, gl.DONT_CARE, 0, nil, gl.TRUE)
}
