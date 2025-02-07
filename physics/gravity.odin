package physics
vec3 :: [3]f32
@(private)
GRAVITY :: -9.8
GRAVITY_VEC3: vec3 : {0, GRAVITY, 0} // This applies gravity in the Y direction
Physics :: struct {
	mass:       f32,
	iMass:      f32,
	vel:        vec3,
	acc:        vec3,
	forceAccum: vec3,
}

clearForces :: proc(p: ^Physics) {
	p.forceAccum = {}
}


applyKinematics :: proc(p: ^Physics, pos: vec3, time: f32) -> vec3 {
	p.acc = p.forceAccum / p.mass
	new_vel := p.vel + p.acc * time
	pos_change := (p.vel + new_vel) * 0.5 * time
	p.vel = new_vel
	clearForces(p) // Clear forces after applying them

	// Apply kinematics, handle collision with the ground (pos.y <= 0)
	new_pos := pos + pos_change

	if new_pos.y <= -2 {
		new_pos.y = -2 // Correct the position to ground level
		p.vel.y = 0 // Stop velocity in Y direction (or apply bounce logic)
	}

	return new_pos - pos // Return the change in position
}

applyGravity :: proc(p: ^Physics, pos: vec3) {
	// Gravity always pulls down in the Y direction
	p.forceAccum += GRAVITY_VEC3 * p.mass
}
