local graphics = love.graphics

-- love.window.setMode(0, 0, {fullscreen = true})

local game_over

graphics.setBackgroundColor(32, 32, 64)
graphics.setColor(255, 255, 240)

local function start()

local scale = 20

local top_terrain = {}
local bottom_terrain = {}

local function is_colliding(x, y)
	local i = math.floor(x)
	return
		(top_terrain   [i] and top_terrain   [i] < y) or
		(bottom_terrain[i] and bottom_terrain[i] > y)
end

local function draw_terrain(terrain, x_start, x_end)
	local points = {}
	for i = math.floor(x_start), math.ceil(x_end) do
		if terrain[i] then
			table.insert(points, i)
			table.insert(points, terrain[i])
		end
	end
	if #points >= 4 then
		graphics.line(points)
	end
end

function update_terrain(terrain, fun, x_start, x_end)
	local i_start, i_end = math.floor(x_start), math.ceil(x_end)
	local to_remove = {}
	for i, v in pairs(terrain) do
		if i < i_start or i > i_end then
			table.insert(to_remove, i)
		end
	end
	for _, i in ipairs(to_remove) do
		terrain[i] = nil
	end
	for i = i_start, i_end do
		if not terrain[i] then
			terrain[i] = fun(i)
		end
	end
end

local function noise(x)
	return (love.math.noise(x) - 0.5) * 2
end

local function large_scale_noise(i)
	return noise(i / 30) * 15
end

local function top_fun(i)
	return large_scale_noise(i) + noise(i / 5 + 4362104) * 4.5
end

local function bottom_fun(i)
	return large_scale_noise(i) - 17 + noise(i / 5 + 574027) * 4.5
end

local lookahead = graphics.getWidth() / scale

local cam_x = 0
local cam_y = 0

local px, py = 6, -1
local pvx, pvy = 10, 0

local function draw_player()
	graphics.setLineWidth(0.1)
	-- jetpack
	graphics.rectangle('line', -0.5, -0.5, 0.5, 1.2)
	if love.keyboard.isDown(" ") then
		graphics.push 'all'
		graphics.setColor(255, 128, 0)
		graphics.polygon('fill', -0.5, -0.5, 0, -0.5, -0.25, -1.5)
		graphics.pop()
	end
	-- head
	graphics.circle('line', 0, 1.5, 0.5)
	graphics.line(0, 1, 0, -0.75)
	-- legs
	graphics.line(0, -0.75, -0.25 + 0.2, -1.5, -0.75 + 0.2, -1.75)
	graphics.line(0, -0.75, 0.25 + 0.2, -1.5, -0.25 + 0.2, -1.9)
	-- arms
	graphics.line(0, 1, -0.4, 0, 0.25, -0.25)
end

function love.draw()
	graphics.translate(0, graphics.getHeight() / 2)
	graphics.scale(scale, -scale)
	
	graphics.translate(-cam_x, -cam_y)
	graphics.push()
		graphics.translate(px, py)
		draw_player()
	graphics.pop()
	-- graphics.circle('fill', px, py, 1)
	graphics.setLineWidth(0.2)
	draw_terrain(top_terrain, cam_x, cam_x + lookahead)
	draw_terrain(bottom_terrain, cam_x, cam_x + lookahead)
end

local gravity = 20
local jetpack = 2.5 * gravity

function love.update(dt)
	dt = dt * 1.2
	
	update_terrain(top_terrain, top_fun, cam_x, cam_x + lookahead)
	update_terrain(bottom_terrain, bottom_fun, cam_x, cam_x + lookahead)
	
	pvy = pvy - gravity * dt
	if love.keyboard.isDown ' ' then
		pvy = pvy + jetpack * dt
	end
	
	px = px + pvx * dt
	py = py + pvy * dt
	
	cam_x = px - 5
	cam_y = cam_y + (py - cam_y) * dt
	
	-- check for collisions
	if is_colliding(px, py + 1.8) or is_colliding(px, py - 1.8) then
		game_over()
	end
end

function love.keypressed(k)
end

end

local font = graphics.newFont(60)
graphics.setFont(font)

function game_over()
	function love.draw()
		graphics.printf("GAME OVER\n\nPRESS SPACE TO START", 0, 20, graphics.getWidth(), 'center')
	end
	
	function love.update(dt)
	end
	
	function love.keypressed(k)
		if k == ' ' then
			start()
		end
	end
end

game_over()
