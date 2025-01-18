package physics


Physics :: struct {
	mass:  f32,
	iMass: f32,
	vel:   vec3,
	acc:   vec3,
	pos:   vec3,
}
vec3 :: [3]f32

applyKinematics :: proc(p: ^Physics, time: f32) -> vec3 {
	return 0.5 * p.acc * time * time + p.vel * time
}

@(private)
GRAVITY :: -9.8

@(private)
GRAVITY_VEC3: vec3 : {0, GRAVITY, 0}

applyGravity :: proc(p: ^Physics, pos: vec3) {
	if pos.y > 0 {
		p.acc += GRAVITY_VEC3
	}
}
