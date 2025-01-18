package gs

SCR_WIDTH :: 1920
SCR_HEIGHT :: 1080

import "core:time"
import sdl "vendor:sdl2"
window: ^sdl.Window = nil
deltaTime: f32 = 0
lastFrame: time.Time = time.from_nanoseconds(0)

FPS :: 144
FRAME_DURATION: f64 = 1 / FPS
