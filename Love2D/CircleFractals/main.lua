math.randomseed(os.time())
for i = 1, 10 do math.random() end

local graphics = love.graphics

local function start()

local iterations = 8

local levels = {}
local first_level = 1

local size = 1024

love.window.setMode(size/2, size/2)

local fold_draw
do
	local temp_canvas_1 = graphics.newCanvas(size, size)
	local temp_canvas_2 = graphics.newCanvas(size, size)
	
	local function fold_draw_helper(draw_objs, i, prev_canvas, curr_canvas)
		local draw_fn = draw_objs[i] and draw_objs[i].draw
		if not draw_fn then
			return prev_canvas
		end
		curr_canvas:clear()
		curr_canvas:renderTo(function()
			draw_fn(prev_canvas)
		end)
		return fold_draw_helper(draw_objs, i + 1, curr_canvas, prev_canvas)
	end
	
	function fold_draw(draw_objs, i)
		i = i or 1
		temp_canvas_1:clear()
		return fold_draw_helper(draw_objs, i, temp_canvas_1, temp_canvas_2)
	end
end

local sub_offset = math.sqrt(2) - 1
local sub_radius = 1 / (math.sqrt(2) + 1)

local function draw_centered_canvas(canvas, x, y, r)
	graphics.draw(canvas,
		-- x
		x,
		-- y
		y,
		-- orientation
		0,
		-- scale x
		2 * r / canvas:getWidth(),
		-- scale y
		2 * r / canvas:getHeight(),
		-- offset x
		canvas:getWidth() / 2,
		-- offset y
		canvas:getHeight() / 2
	)
end

local sub_positions = {
	{ sub_offset,  sub_offset};
	{-sub_offset,  sub_offset};
	{-sub_offset, -sub_offset};
	{ sub_offset, -sub_offset};
}

-- local color = {math.random(0, 64), math.random(0, 128), math.random(128, 255)}
local color = {math.random(128, 255), math.random(128, 255), math.random(128, 255)}

local function gen_level(i)
	local this = {}
	
	local brightness = math.random() * 0.75 + 0.25
	this.color = {color[1] * brightness, color[2] * brightness, color[3] * brightness}
	-- this.angle = math.random() * math.pi
	this.angle = 0
	this.rotation_rate = (math.random() - 0.5) / 4
	print(this.angle)
	this.selected_sub = math.random(1, 4)
	this.opacity = 255
	
	function this.draw(prev_canvas)
		graphics.push()
			graphics.setLineWidth(0.05)
			graphics.translate(size / 2, size / 2)
			graphics.scale(size / 2, size / 2)
			-- graphics.rotate(this.angle)
			graphics.rotate(this.angle)
			graphics.setColor(this.color[1], this.color[2], this.color[3], this.opacity)
			graphics.circle('fill', 0, 0, 1, 50)
			graphics.setColor(0, 0, 0, this.opacity)
			graphics.circle('line', 0, 0, 1, 50)
			-- graphics.line(0, 0, 1, 0)
			graphics.setColor(255, 255, 255)
			for _, pos in ipairs(sub_positions) do
				draw_centered_canvas(prev_canvas, pos[1], pos[2], sub_radius)
			end
		graphics.pop()
	end
	
	levels[i] = this
end

for i = 1, iterations do
	gen_level(i)
end

local function linear_interp(a, b, factor)
	return b * factor + a * (1 - factor)
end

local function cosine_interp(a, b, factor)
	return linear_interp(a, b, -(1/2)*math.cos(math.pi*factor) + 1/2)
end

local interp_factor = 0

function love.draw()
	local canvas = fold_draw(levels, first_level)
	graphics.push()
		graphics.translate(size / 4, size / 4)
		graphics.scale(size / 4, size / 4)
		levels[first_level + iterations - 1].opacity = 255 * (1 - interp_factor)
		local interp_angle = cosine_interp(0, -levels[first_level + iterations - 1].angle, interp_factor)
		-- print(interp_angle / levels[first_level].angle)
		local selected = levels[first_level + iterations - 1].selected_sub
		local sub_x, sub_y = unpack(sub_positions[selected])
		local offset_x = cosine_interp(0, sub_x, interp_factor)
		local offset_y = cosine_interp(0, sub_y, interp_factor)
		local scale = cosine_interp(1, 1/sub_radius, interp_factor)
		graphics.scale(scale, scale)		
		graphics.translate(-offset_x, -offset_y)
		graphics.rotate(interp_angle)
		draw_centered_canvas(canvas, 0, 0, 1)
	graphics.pop()
end

function love.update(dt)
	interp_factor = interp_factor + dt / 8
	if interp_factor > 1 then
		interp_factor = interp_factor % 1
		levels[first_level + iterations - 1] = nil
		first_level = first_level - 1
		gen_level(first_level)
	end
	
	for i = first_level, first_level + iterations - 1 do
		levels[i].angle = levels[i].angle + dt * levels[i].rotation_rate
	end
end

function love.keypressed(k)
	start()
end

end

start()
