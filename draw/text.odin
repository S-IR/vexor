package draw
import "../gs"
import "core:os"
import gl "vendor:OpenGL"
import "vendor:nanovg"
import nvg "vendor:nanovg/gl"

drawText :: proc(text: string = "hello world", x, y: f32) {
	using gs

	// Save GL state
	gl.Disable(gl.DEPTH_TEST)
	gl.Disable(gl.CULL_FACE)
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	// Transform coordinates to match screen space
	nanovg.BeginFrame(vgCtx, f32(SCR_WIDTH), f32(SCR_HEIGHT), 1.0)
	nanovg.Save(vgCtx)

	// Reset transform
	nanovg.ResetTransform(vgCtx)

	// Set text properties
	nanovg.FontFace(vgCtx, "Arial")
	nanovg.FontSize(vgCtx, 48)
	nanovg.TextAlign(vgCtx, .LEFT, .TOP)
	nanovg.FillColor(vgCtx, nanovg.RGBA(255, 255, 255, 255))

	// Draw text
	textWidth := nanovg.Text(vgCtx, x, y, text)
	assert(textWidth > 0, "TEXT WIDTH IS LESS THAN 0")

	// Cleanup
	nanovg.Restore(vgCtx)
	nanovg.EndFrame(vgCtx)

	// Restore GL state
	gl.Enable(gl.DEPTH_TEST)
	gl.Enable(gl.CULL_FACE)
	gl.Disable(gl.BLEND)
}
