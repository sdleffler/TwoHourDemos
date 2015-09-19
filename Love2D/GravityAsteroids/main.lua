local physics, graphics = love.physics, love.graphics
local keydown = love.keyboard.isDown

physics.setMeter(1)

math.randomseed(os.time())
for i = 1, 10 do math.random() end

local world = physics.newWorld(0, 0, false)

local function random_asteroid_shape(size, vert_count)
	assert(vert_count <= 8, "Box2D does not support > 8 vertices in a polygon shape!")
	
	local vert_angles = {}
	for i = 1, vert_count do
		table.insert(vert_angles, math.random() * 2 * math.pi)
	end
	table.sort(vert_angles)
	local verts = {}
	for i, vert_angle in ipairs(vert_angles) do
		verts[(i-1)*2+1] = math.cos(vert_angle) * size
		verts[(i-1)*2+2] = math.sin(vert_angle) * size
	end
	print(#verts)
	return physics.newPolygonShape(unpack(verts))
end

local function new_asteroid(params)	
	local this = physics.newBody(world, params.x, params.y, 'dynamic')
	local shape = random_asteroid_shape(params.size, params.vert_count)
	local fix = physics.newFixture(this, shape, params.density)
	this:setPosition(params.x, params.y)
	this:setLinearVelocity(params.velocity_x, params.velocity_y)
	this:setAngularVelocity(params.angular_velocity)
	
	local udata = {}
	
	udata.feels_gravity = true
	
	function udata.draw()
		graphics.push 'all'
			graphics.setColor(255, 0, 0)
			graphics.polygon('line', this:getWorldPoints(shape:getPoints()))
		graphics.pop()
	end
		
	this:setUserData(udata)
	
	return this
end

-- new_asteroid {
-- 	x = -5, y = 0;
-- 	velocity_x = 0; velocity_y = 5;
-- 	angular_velocity = 1;
-- 	density = 1;
-- 	vert_count = 5;
-- 	size = 2;
-- }

for i = 1, 40 do
	local theta = math.random() * 2 * math.pi
	local r = math.random() * 30 + 10
	local c = math.cos(theta)
	local s = math.sin(theta)
	local v = math.sqrt(2000/r)
	new_asteroid {
		x = c * r, y = s * r;
		velocity_x = -s * v, velocity_y = c * v;
		angular_velocity = math.random();
		density = 1;
		vert_count = math.random(3, 8);
		size = math.random(1, 2);
	}
end

local player_shape = physics.newPolygonShape (
	 2,  0,
	-1,  1,
	-1, -1
)

local key_bindings = {
	rotate_left     = "a";
	rotate_right    = "d";
	
	thrust_forward  = "w";
	thrust_backward = "s";
	thrust_left     = "q";
	thrust_right    = "e";
}

local function new_player(params)
	local this = physics.newBody(world, params.x, params.y, 'dynamic')
	local shape = player_shape
	physics.newFixture(this, shape, params.density)
	this:setLinearVelocity(params.velocity_x, params.velocity_y)
	this:setAngularVelocity(params.angular_velocity)
	
	local udata = {}
	
	udata.feels_gravity = true
	
	function udata.draw()
		graphics.push 'all'
			graphics.setColor(255, 255, 255)
			graphics.polygon('line', this:getWorldPoints(shape:getPoints()))
		graphics.pop()
	end
	
	local function apply_thrust(fx, fy)
		this:applyForce(this:getWorldVector(
			params.thruster_force * fx,
			params.thruster_force * fy
		))
	end
	
	function udata.update(dt)
		if     keydown(key_bindings.rotate_left) then
			this:applyTorque(-params.thruster_torque)
		elseif keydown(key_bindings.rotate_right) then
			this:applyTorque( params.thruster_torque)
		else
			-- Automatically kill rotation
			local x0, y0 = this:getPosition()
			local vx, vy = this:getLinearVelocity()
			local natural_rotation = (vy*x0)/(x0^2 + y0^2) - (vx*y0)/(x0^2 + y0^2)
			this:applyTorque(-(this:getAngularVelocity() - natural_rotation) * 5)
		end		
		
		if     keydown(key_bindings.thrust_forward) then
			-- this:applyForce(this:getWorldVector( params.thruster_force, 0))
			apply_thrust(1, 0)
		elseif keydown(key_bindings.thrust_backward) then
			-- this:applyForce(this:getWorldVector(-params.thruster_force, 0))
			apply_thrust(-1, 0)
		end
		
		if     keydown(key_bindings.thrust_left) then
			apply_thrust(0, -1)
		elseif keydown(key_bindings.thrust_right) then
			apply_thrust(0, 1)
		end
	end
	
	this:setUserData(udata)
	
	return this
end

local function new_planet(params)
	local this = physics.newBody(world, 0, 0, 'static')
	physics.newFixture(this, physics.newCircleShape(0, 0, params.size))
	
	local udata = {}
	
	function udata.draw()
		graphics.push 'all'
			graphics.setColor(0, 255, 255)
			graphics.circle('line', 0, 0, params.size, 6)
		graphics.pop()
	end
	
	local function apply_gravity(body)
		local x, y = body:getPosition()
		local mag = math.sqrt(x*x + y*y)
		-- normalize
		x = x / mag
		y = y / mag
		local local_g = -params.gravity / mag^2
		local gx = local_g * x
		local gy = local_g * y
		body:applyForce(body:getMass() * gx, body:getMass() * gy)
	end
	
	function udata.update(dt)
		for _, body in ipairs(world:getBodyList()) do
			local udata = body:getUserData()
			if udata and udata.feels_gravity then
				apply_gravity(body)
			end
		end
	end
	
	this:setUserData(udata)
	
	return this
end

new_player {
	x = 10; y = 0;
	velocity_x = 0; velocity_y = math.sqrt(2000/10);
	angular_velocity = 0;
	density = 1;
	thruster_force = 50;
	thruster_torque = 25;
}

local pixels_per_meter = 10

local function body_event(event, ...)
	for _, body in ipairs(world:getBodyList()) do
		local udata = body:getUserData()
		if udata and udata[event] then
			udata[event](...)
		end
	end
end

function love.draw()
	graphics.push 'all'
		graphics.setLineWidth(1.5 / pixels_per_meter)
		graphics.translate(graphics.getWidth() / 2, graphics.getHeight() / 2)
		graphics.scale(pixels_per_meter, pixels_per_meter)
		body_event 'draw'
	graphics.pop()
end

-- local gravity = 300

new_planet {
	size = 5; --1;
	gravity = 2000;
}

function love.update(dt)
	body_event('update', dt)
	world:update(dt)
end
