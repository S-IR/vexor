package gs

SCR_WIDTH :: 1920
SCR_HEIGHT :: 1080

import "../submodules/freetype"
import "core:time"
import "vendor:nanovg"
import sdl "vendor:sdl2"
window: ^sdl.Window = nil
ft_library: freetype.Library
deltaTime: f32 = 0
lastFrame: time.Time = time.from_nanoseconds(0)
FPS :: 144
vgCtx: ^nanovg.Context
FRAME_DURATION: f64 = 1 / FPS
