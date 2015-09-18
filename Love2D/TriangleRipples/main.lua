function Triangle(x, width, dir, tess, y, add_child)
	add_child = add_child or function() end
	tess = tess or 0
	y = y or 0

	assert(tess ~= 1)

	local newtri = {}

	newtri.width = width

	local d = math.sqrt(width^2 - (width/2)^2) * dir
	local b_max = 64
	local b = math.random(b_max)

	newtri.yverts = { d/2 + y, d/2 + y, -d/2 + y }
	newtri.color = { b, b, b + (128 - b_max) + math.random(127) }
	newtri.children = {}
	newtri.x = x
	newtri.y = y

	function newtri.draw(ripple_func)
		love.graphics.setColor(newtri.color)
		love.graphics.polygon('fill', newtri.x + math.sin(ripple_func(newtri.x, newtri.y)) * width, newtri.yverts[1], newtri.x + width - math.sin(ripple_func(newtri.x, newtri.y)) * width, newtri.yverts[2], (newtri.x + width/2), newtri.yverts[3])
	end

	function newtri.update(dt, bounds)
		if newtri.x + dt/width > bounds/2 then
			newtri.x = newtri.x + dt / width - bounds
		else
			newtri.x = newtri.x + dt / width
		end
	end

	if tess ~= 0 then
		if math.random(tess) == 1 then
			add_child(Triangle(x, width/2, dir, tess + 1, y + d/4, add_child))
		end
		if math.random(tess) == 1 then
			add_child(Triangle(x + width/2, width/2, dir, tess + 1, y + d/4, add_child))
		end
		if math.random(tess) == 1 then
			add_child(Triangle(x + width/4, width/2, dir, tess + 1, y - d/4, add_child))
		end
	end

	return newtri
end

function generate_tris(width, height)
	math.random()
	triangles = {}
	for j=-height,height,math.sqrt(0.75) do
		for i=-width,width do
			local x, dir = i/2, ({-1, 1})[(i % 2) + 1]
			table.insert(triangles, Triangle(x, 1, dir, 5, j, function(child) table.insert(triangles, child) end))
		end
	end
	table.sort(triangles, function(tri1, tri2) return tri1.width > tri2.width end)
end

function love.resize(w, h)
	width = math.ceil(w/64) + 2
	height = math.ceil(h/64)
	
	generate_tris(width, height)
end

function love.keypressed(key, isrepeat)
	if key == "f" then
		love.window.setFullscreen(not love.window.getFullscreen())
	end
end

function love.load()
	math.randomseed(os.time())

	diagnostics = false

	love.window.setMode(0, 0, { resizable = true })

	--ripple_state = { ripple_chance = 90, rippling = false, time_rippled = 0, ripple_width_coeff = 128, radius_per_time = 1, max_time = 60, min_time = -20, x_orig = 0, y_orig = 0 }
	ripple_state = { ripple_chance = 20, rippling = false, time_rippled = 0, ripple_width_coeff = 1, radius_per_time = 2, max_time = 20, min_time = 0, x_orig = 0, y_orig = 0 }
	function ripple_state.ripple_func(x, y)
		if ripple_state.rippling then
			return math.pi * math.exp((1/ripple_state.ripple_width_coeff) * -(math.sqrt((x - ripple_state.x_orig)^2 + (y - ripple_state.y_orig)^2) - (ripple_state.time_rippled * ripple_state.radius_per_time))^2)
		else
			return 0
		end
	end

	function ripple_state.update(dt)
		if ripple_state.rippling and ripple_state.time_rippled < ripple_state.max_time then
			ripple_state.time_rippled = ripple_state.time_rippled + dt * ripple_state.radius_per_time
		else
			ripple_state.time_rippled = 0
			ripple_state.rippling = false
		end
	end

	function ripple_state.begin_ripple(x, y)
		ripple_state.rippling = true
		ripple_state.time_rippled = ripple_state.min_time
		ripple_state.x_orig = x
		ripple_state.y_orig = y
	end

	local b_max = 64
	local b = math.random(b_max)
	love.graphics.setBackgroundColor(b, b, b + (128 - b_max) + math.random(128))
end

function love.draw()
	love.graphics.push()
	love.graphics.translate(love.window.getWidth()/2, love.window.getHeight()/2)
	love.graphics.scale(64, 64)

	for i,v in ipairs(triangles) do
		v.draw(ripple_state.ripple_func)
	end

	love.graphics.pop()

	if diagnostics then
		love.graphics.setColor(255, 0, 0, 255)
		love.graphics.print("[Ripple time: " .. ripple_state.time_rippled .. "/" .. ripple_state.max_time .. "]", 8, 8)
	end
end

function love.update(dt)
	for i,v in ipairs(triangles) do
		v.update(dt, width)
	end

	if not ripple_state.rippling and math.random(ripple_state.ripple_chance) == 1 then
		ripple_state.begin_ripple(math.random(width * 2) - width, math.random(height * 2) - height)
	end
	ripple_state.update(dt)
end